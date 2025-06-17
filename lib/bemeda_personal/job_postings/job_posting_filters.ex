defmodule BemedaPersonal.JobPostings.JobPostingFilters do
  @moduledoc """
  Filter configuration for job postings.
  """

  import Ecto.Query

  alias BemedaPersonal.QueryBuilder

  @spec filter_config() :: QueryBuilder.t()
  def filter_config do
    %QueryBuilder{
      default_alias: :job_posting,
      filter_functions: Map.merge(basic_filters(), advanced_filters())
    }
  end

  defp basic_filters do
    %{
      company_id: &QueryBuilder.exact_match_filter(:company_id, &1),
      currency: &QueryBuilder.exact_match_filter(:currency, &1),
      employment_type: &QueryBuilder.exact_match_filter(:employment_type, &1),
      experience_level: &QueryBuilder.exact_match_filter(:experience_level, &1),
      location: &QueryBuilder.ilike_filter(:location, &1),
      position: &QueryBuilder.exact_match_filter(:position, &1),
      profession: &QueryBuilder.exact_match_filter(:profession, &1),
      remote_allowed: &QueryBuilder.boolean_filter(:remote_allowed, &1),
      search: &full_text_search_filter/1,
      years_of_experience: &QueryBuilder.exact_match_filter(:years_of_experience, &1)
    }
  end

  defp advanced_filters do
    %{
      department: &array_overlap_filter(:department, &1),
      language: &array_overlap_filter(:language, &1),
      newer_than: &newer_than_filter/1,
      older_than: &older_than_filter/1,
      region: &array_overlap_filter(:region, &1),
      salary_max: &salary_max_filter/1,
      salary_min: &salary_min_filter/1,
      salary_range: &salary_range_filter/1,
      shift_type: &array_overlap_filter(:shift_type, &1),
      workload: &array_overlap_filter(:workload, &1)
    }
  end

  defp array_overlap_filter(field, filter_values) when is_list(filter_values) do
    string_values = Enum.map(filter_values, &to_string/1)

    fn _value, dynamic, alias ->
      dynamic(
        [{^alias, entity}],
        ^dynamic and fragment("? && ?", field(entity, ^field), ^string_values)
      )
    end
  end

  defp array_overlap_filter(field, filter_value) do
    array_overlap_filter(field, [filter_value])
  end

  defp salary_min_filter(min_salary) when is_integer(min_salary) do
    fn _value, dynamic, alias ->
      dynamic([{^alias, entity}], ^dynamic and field(entity, :salary_max) >= ^min_salary)
    end
  end

  defp salary_max_filter(max_salary) when is_integer(max_salary) do
    fn _value, dynamic, alias ->
      dynamic([{^alias, entity}], ^dynamic and field(entity, :salary_min) <= ^max_salary)
    end
  end

  defp salary_range_filter([min, max]) do
    QueryBuilder.numeric_range_filter(:salary_min, :salary_max, {min, max})
  end

  defp newer_than_filter(%{inserted_at: inserted_at}) do
    fn _value, dynamic, alias ->
      dynamic([{^alias, entity}], ^dynamic and field(entity, :inserted_at) > ^inserted_at)
    end
  end

  defp older_than_filter(%{inserted_at: inserted_at}) do
    fn _value, dynamic, alias ->
      dynamic([{^alias, entity}], ^dynamic and field(entity, :inserted_at) < ^inserted_at)
    end
  end

  defp full_text_search_filter(search_term) when is_binary(search_term) and search_term != "" do
    cleaned_term =
      search_term
      |> String.trim()
      |> String.downcase()

    search_query = cleaned_term

    ilike_pattern = "%#{cleaned_term}%"

    fn _value, dynamic, alias ->
      dynamic(
        [{^alias, entity}],
        ^dynamic and
          (fragment(
             "to_tsvector('english', coalesce(?, '') || ' ' || coalesce(?, '')) @@ plainto_tsquery('english', ?)",
             field(entity, :title),
             field(entity, :description),
             ^search_query
           ) or
             ilike(field(entity, :title), ^ilike_pattern) or
             ilike(field(entity, :description), ^ilike_pattern))
      )
    end
  end

  defp full_text_search_filter(_search_term), do: fn _value, dynamic, _alias -> dynamic end
end
