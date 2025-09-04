defmodule BemedaPersonal.QueryBuilder do
  @moduledoc """
  Generic query builder for applying filters to Ecto queries.
  Provides reusable filter functions and a configurable filtering system.
  """

  import Ecto.Query

  alias BemedaPersonal.DateUtils

  defstruct filter_functions: %{}, default_alias: :entity, joins: []

  @type date_input :: Date.t() | String.t()
  @type date_range :: {date_input(), date_input()}
  @type dynamic_expr :: Ecto.Query.dynamic_expr()
  @type field :: atom()
  @type filter_builder :: (any() -> filter_function())
  @type filter_function :: (any(), dynamic_expr(), atom() -> dynamic_expr())
  @type filter_functions_map :: %{atom() => filter_function() | filter_builder()}
  @type filter_map :: %{atom() => any()}
  @type join_spec :: {:left | :inner, atom(), atom()}
  @type numeric_range :: {number(), number()}
  @type query :: Ecto.Query.t()
  @type queryable :: Ecto.Queryable.t()
  @type t :: %__MODULE__{}

  @doc """
  Apply filters to a queryable using the provided configuration.

  ## Examples

      iex> config = %{
      ...>   filter_functions: %{
      ...>     title: &QueryBuilder.ilike_filter(:title, &1),
      ...>     company_id: &QueryBuilder.exact_match_filter(:company_id, &1)
      ...>   },
      ...>   default_alias: :job_posting
      ...> }
      ...>
      ...> QueryBuilder.apply_filters(JobPosting, %{title: "Engineer"}, config)
      #Ecto.Query<...>

  """
  @spec apply_filters(queryable(), map()) :: query()
  def apply_filters(queryable, filters), do: apply_filters(queryable, filters, %__MODULE__{})

  @spec apply_filters(queryable(), map(), t()) :: query()
  def apply_filters(queryable, filters, config) do
    default_alias = config.default_alias

    query =
      case queryable do
        %Ecto.Query{} = q -> q
        schema -> from(entity in schema, as: ^default_alias)
      end

    query_with_joins = apply_joins(query, config.joins)

    if Enum.empty?(filters) do
      query_with_joins
    else
      dynamic_filter = build_dynamic_filter(filters, config.filter_functions, default_alias)
      where(query_with_joins, ^dynamic_filter)
    end
  end

  @doc """
  Build a dynamic filter from filters map and filter functions.
  """
  @spec build_dynamic_filter(filter_map(), filter_functions_map(), atom()) :: dynamic_expr()
  def build_dynamic_filter(filters, filter_functions, default_alias) do
    Enum.reduce(filters, dynamic(true), fn {key, value}, acc ->
      apply_single_filter(Map.get(filter_functions, key), value, acc, default_alias)
    end)
  end

  defp apply_single_filter(nil, _value, acc, _alias), do: acc

  defp apply_single_filter(filter_fn, value, acc, alias) when is_function(filter_fn, 1) do
    actual_filter = filter_fn.(value)
    actual_filter.(value, acc, alias)
  end

  defp apply_single_filter(filter_fn, value, acc, alias) when is_function(filter_fn, 3) do
    filter_fn.(value, acc, alias)
  end

  defp apply_single_filter(_other, _value, acc, _alias), do: acc

  # Common filter functions

  @doc """
  Create an exact match filter for a field.
  """
  @spec exact_match_filter(field(), any()) :: filter_function()
  def exact_match_filter(field, value) do
    fn _filter_value, dynamic, alias ->
      dynamic([{^alias, entity}], ^dynamic and field(entity, ^field) == ^value)
    end
  end

  @doc """
  Create an ILIKE filter for text search.
  """
  @spec ilike_filter(field(), String.t() | atom()) :: filter_function()
  def ilike_filter(field, value) when is_binary(value) or is_atom(value) do
    string_value = if is_atom(value), do: Atom.to_string(value), else: value
    pattern = "%#{String.trim(string_value)}%"

    fn _filter_value, dynamic, alias ->
      dynamic([{^alias, entity}], ^dynamic and ilike(field(entity, ^field), ^pattern))
    end
  end

  @doc """
  Create a date range filter.
  """
  @spec date_range_filter(field(), date_range()) :: filter_function()
  def date_range_filter(field, {from_date, to_date}) do
    fn _filter_value, dynamic, alias ->
      case build_date_range(from_date, to_date) do
        {from_datetime, to_datetime} ->
          dynamic(
            [{^alias, entity}],
            ^dynamic and
              field(entity, ^field) >= ^from_datetime and
              field(entity, ^field) <= ^to_datetime
          )

        nil ->
          dynamic
      end
    end
  end

  defp build_date_range(from_date, to_date) do
    with from_date when is_struct(from_date, Date) <- DateUtils.ensure_date(from_date),
         to_date when is_struct(to_date, Date) <- DateUtils.ensure_date(to_date) do
      {from_datetime, _end_of_from_day} = DateUtils.date_to_datetime_range(from_date)
      {_start_of_to_day, to_datetime} = DateUtils.date_to_datetime_range(to_date)
      {from_datetime, to_datetime}
    else
      _error -> nil
    end
  end

  @doc """
  Create a date from filter (greater than or equal).
  """
  @spec date_from_filter(field(), date_input()) :: filter_function()
  def date_from_filter(field, from_date) do
    fn _filter_value, dynamic, alias ->
      case DateUtils.ensure_date(from_date) do
        nil ->
          dynamic

        date ->
          {from_datetime, _end_of_day} = DateUtils.date_to_datetime_range(date)
          dynamic([{^alias, entity}], ^dynamic and field(entity, ^field) >= ^from_datetime)
      end
    end
  end

  @doc """
  Create a date to filter (less than or equal).
  """
  @spec date_to_filter(field(), date_input()) :: filter_function()
  def date_to_filter(field, to_date) do
    fn _filter_value, dynamic, alias ->
      case DateUtils.ensure_date(to_date) do
        nil ->
          dynamic

        date ->
          {_start_of_day, to_datetime} = DateUtils.date_to_datetime_range(date)
          dynamic([{^alias, entity}], ^dynamic and field(entity, ^field) <= ^to_datetime)
      end
    end
  end

  @doc """
  Create a numeric range filter.
  """
  @spec numeric_range_filter(field(), field(), numeric_range()) :: filter_function()
  def numeric_range_filter(min_field, max_field, {min_value, max_value}) do
    fn _filter_value, dynamic, alias ->
      dynamic(
        [{^alias, entity}],
        ^dynamic and
          field(entity, ^min_field) <= ^max_value and
          field(entity, ^max_field) >= ^min_value
      )
    end
  end

  @doc """
  Create an IN filter for multiple values.
  """
  @spec in_filter(field(), [any()]) :: filter_function()
  def in_filter(field, values) when is_list(values) and length(values) > 0 do
    fn _filter_value, dynamic, alias ->
      dynamic([{^alias, entity}], ^dynamic and field(entity, ^field) in ^values)
    end
  end

  @doc """
  Create a boolean filter.
  """
  @spec boolean_filter(field(), boolean()) :: filter_function()
  def boolean_filter(field, value) when is_boolean(value) do
    fn _filter_value, dynamic, alias ->
      dynamic([{^alias, entity}], ^dynamic and field(entity, ^field) == ^value)
    end
  end

  @doc """
  Create a subquery filter for associations.
  """
  @spec subquery_filter(module(), field(), any()) :: filter_function()
  def subquery_filter(schema, field, value) do
    fn _filter_value, dynamic, alias ->
      subquery = from(s in schema, where: field(s, ^field) == ^value, select: s.id)
      dynamic([{^alias, entity}], ^dynamic and field(entity, :id) in subquery(subquery))
    end
  end

  defp apply_joins(queryable, []), do: queryable

  defp apply_joins(queryable, joins) do
    Enum.reduce(joins, queryable, fn {join_type, association, alias}, query ->
      case join_type do
        :left -> join(query, :left, [entity], assoc in assoc(entity, ^association), as: ^alias)
        :inner -> join(query, :inner, [entity], assoc in assoc(entity, ^association), as: ^alias)
        _other -> query
      end
    end)
  end
end
