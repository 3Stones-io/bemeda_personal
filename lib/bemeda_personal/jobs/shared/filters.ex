defmodule BemedaPersonal.Jobs.Shared.Filters do
  @moduledoc """
  Shared filtering functionality for job applications.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Jobs.JobApplicationTag
  alias BemedaPersonal.Jobs.Tag

  @type date_input :: binary() | Date.t() | any()
  @type date_range :: %{from: date_input(), to: date_input()}
  @type date_string :: String.t()
  @type dynamic_expr :: Ecto.Query.dynamic_expr()
  @type filter_key :: atom()
  @type filter_tuple :: {filter_key(), filter_value()}
  @type filter_value :: any()
  @type parse_result :: {:ok, Date.t()} | {:error, any()}

  @doc """
  Applies job application filters to a dynamic query.
  """
  @spec apply_job_application_filters() :: (map() -> dynamic_expr())
  def apply_job_application_filters do
    fn filters ->
      Enum.reduce(filters, dynamic(true), &apply_job_application_filter/2)
    end
  end

  @doc """
  Applies a single job application filter to a dynamic query.
  """
  @spec apply_job_application_filter(filter_tuple(), dynamic_expr()) :: dynamic_expr()
  def apply_job_application_filter({:user_id, user_id}, dynamic) do
    dynamic([job_application: ja], ^dynamic and ja.user_id == ^user_id)
  end

  @spec apply_job_application_filter(filter_tuple(), dynamic_expr()) :: dynamic_expr()
  def apply_job_application_filter({:job_posting_id, job_posting_id}, dynamic) do
    dynamic([job_application: ja], ^dynamic and ja.job_posting_id == ^job_posting_id)
  end

  @spec apply_job_application_filter(filter_tuple(), dynamic_expr()) :: dynamic_expr()
  def apply_job_application_filter({:company_id, company_id}, dynamic) do
    dynamic([job_application: ja, job_posting: jp], ^dynamic and jp.company_id == ^company_id)
  end

  @spec apply_job_application_filter(filter_tuple(), dynamic_expr()) :: dynamic_expr()
  def apply_job_application_filter({:date_range, %{from: from_date, to: to_date}}, dynamic)
      when is_nil(from_date) or is_nil(to_date),
      do: dynamic

  @spec apply_job_application_filter(filter_tuple(), dynamic_expr()) :: dynamic_expr()
  def apply_job_application_filter({:date_range, %{from: from_date, to: to_date}}, dynamic) do
    from_date = parse_date_if_string(from_date)
    to_date = parse_date_if_string(to_date)

    from_datetime = DateTime.new!(from_date, ~T[00:00:00.000], "Etc/UTC")
    to_datetime = DateTime.new!(to_date, ~T[23:59:59.999], "Etc/UTC")

    dynamic(
      [job_application: ja],
      ^dynamic and ja.inserted_at >= ^from_datetime and ja.inserted_at <= ^to_datetime
    )
  end

  @spec apply_job_application_filter(filter_tuple(), dynamic_expr()) :: dynamic_expr()
  def apply_job_application_filter({:date_from, from_date}, dynamic) when is_nil(from_date),
    do: dynamic

  @spec apply_job_application_filter(filter_tuple(), dynamic_expr()) :: dynamic_expr()
  def apply_job_application_filter({:date_from, from_date}, dynamic) do
    from_date = parse_date_if_string(from_date)
    from_datetime = DateTime.new!(from_date, ~T[00:00:00.000], "Etc/UTC")

    dynamic([job_application: ja], ^dynamic and ja.inserted_at >= ^from_datetime)
  end

  @spec apply_job_application_filter(filter_tuple(), dynamic_expr()) :: dynamic_expr()
  def apply_job_application_filter({:date_to, to_date}, dynamic) when is_nil(to_date),
    do: dynamic

  @spec apply_job_application_filter(filter_tuple(), dynamic_expr()) :: dynamic_expr()
  def apply_job_application_filter({:date_to, to_date}, dynamic) do
    to_date = parse_date_if_string(to_date)
    to_datetime = DateTime.new!(to_date, ~T[23:59:59.999], "Etc/UTC")

    dynamic([job_application: ja], ^dynamic and ja.inserted_at <= ^to_datetime)
  end

  @spec apply_job_application_filter(filter_tuple(), dynamic_expr()) :: dynamic_expr()
  def apply_job_application_filter({:applicant_name, name}, dynamic) do
    pattern = "%#{name}%"

    dynamic(
      [job_application: ja],
      ^dynamic and
        exists(
          from u in User,
            where:
              u.id == parent_as(:job_application).user_id and
                (ilike(fragment("concat(?, ' ', ?)", u.first_name, u.last_name), ^pattern) or
                   ilike(fragment("concat(?, ' ', ?)", u.last_name, u.first_name), ^pattern))
        )
    )
  end

  @spec apply_job_application_filter(filter_tuple(), dynamic_expr()) :: dynamic_expr()
  def apply_job_application_filter({:job_title, title}, dynamic) do
    pattern = "%#{title}%"

    dynamic([job_application: ja, job_posting: jp], ^dynamic and ilike(jp.title, ^pattern))
  end

  @spec apply_job_application_filter(filter_tuple(), dynamic_expr()) :: dynamic_expr()
  def apply_job_application_filter({:newer_than, job_application}, dynamic) do
    dynamic([job_application: ja], ^dynamic and ja.inserted_at > ^job_application.inserted_at)
  end

  @spec apply_job_application_filter(filter_tuple(), dynamic_expr()) :: dynamic_expr()
  def apply_job_application_filter({:older_than, job_application}, dynamic) do
    dynamic([job_application: ja], ^dynamic and ja.inserted_at < ^job_application.inserted_at)
  end

  @spec apply_job_application_filter(filter_tuple(), dynamic_expr()) :: dynamic_expr()
  def apply_job_application_filter({:tags, tags}, dynamic) do
    dynamic(
      [job_application: ja],
      ^dynamic and
        ja.id in subquery(
          from jat in JobApplicationTag,
            join: t in Tag,
            on: t.id == jat.tag_id,
            where: t.name in ^tags,
            group_by: jat.job_application_id,
            select: jat.job_application_id
        )
    )
  end

  @spec apply_job_application_filter(filter_tuple(), dynamic_expr()) :: dynamic_expr()
  def apply_job_application_filter({:state, state}, dynamic) do
    dynamic([job_application: ja], ^dynamic and ja.state == ^state)
  end

  @spec apply_job_application_filter(filter_tuple(), dynamic_expr()) :: dynamic_expr()
  def apply_job_application_filter(_other, dynamic), do: dynamic

  @doc """
  Determines if a job posting join is needed based on the filters.
  """
  @spec needs_job_posting_join?(map()) :: boolean()
  def needs_job_posting_join?(filters) do
    filters
    |> Map.keys()
    |> Enum.any?(fn key -> key in [:company_id, :job_title] end)
  end

  # Date parsing functions
  @spec parse_date_if_string(date_input()) :: Date.t() | nil | any()
  defp parse_date_if_string(date) when is_binary(date) do
    parsed_result = parse_date_formats(date)

    case parsed_result do
      {:ok, date} ->
        date

      {:error, _unused} ->
        nil
    end
  end

  defp parse_date_if_string(date), do: date

  @spec parse_date_formats(date_string()) :: parse_result()
  defp parse_date_formats(date_string) do
    iso_result = Date.from_iso8601(date_string)

    case iso_result do
      {:ok, date} ->
        {:ok, date}

      {:error, _unused} ->
        parse_date_ymd(date_string)
    end
  end

  @spec parse_date_ymd(date_string()) :: parse_result()
  defp parse_date_ymd(date_string) do
    cond do
      String.match?(date_string, ~r/^\d{4}-\d{2}-\d{2}$/) ->
        # ISO format YYYY-MM-DD
        {:ok, parse_iso8601_format(date_string)}

      String.match?(date_string, ~r/^\d{2} \/ \d{2} \/ \d{4}$/) ->
        # DD / MM / YYYY format
        parse_date_with_separator(date_string, " / ")

      String.match?(date_string, ~r/^\d{2}\/\d{2}\/\d{4}$/) ->
        # DD/MM/YYYY format
        parse_date_with_separator(date_string, "/")

      String.match?(date_string, ~r/^\d{2}-\d{2}-\d{4}$/) ->
        # DD-MM-YYYY format
        parse_date_with_separator(date_string, "-")

      true ->
        {:error, :invalid_format}
    end
  end

  @spec parse_iso8601_format(date_string()) :: Date.t() | nil
  defp parse_iso8601_format(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      _error -> nil
    end
  end

  @spec parse_date_with_separator(date_string(), String.t()) :: parse_result()
  defp parse_date_with_separator(date_string, separator) do
    [day, month, year] = String.split(date_string, separator)
    parse_date_components(year, month, day)
  end

  @spec parse_date_components(String.t(), String.t(), String.t()) :: parse_result()
  defp parse_date_components(year, month, day) do
    with {y, _remainder_y} <- Integer.parse(year),
         {m, _remainder_m} <- Integer.parse(month),
         {d, _remainder_d} <- Integer.parse(day) do
      case Date.new(y, m, d) do
        {:ok, date} -> {:ok, date}
        _error -> {:error, :invalid_date}
      end
    else
      _error -> {:error, :invalid_components}
    end
  end
end
