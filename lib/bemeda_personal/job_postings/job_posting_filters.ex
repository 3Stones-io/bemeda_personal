defmodule BemedaPersonal.JobPostings.JobPostingFilters do
  @moduledoc """
  Filter configuration for job postings.
  """

  import Ecto.Query

  alias BemedaPersonal.QueryBuilder

  @spec filter_config() :: QueryBuilder.t()
  def filter_config do
    %QueryBuilder{
      filter_functions: %{
        company_id: fn value -> QueryBuilder.exact_match_filter(:company_id, value) end,
        title: fn value -> QueryBuilder.ilike_filter(:title, value) end,
        employment_type: fn value -> QueryBuilder.ilike_filter(:employment_type, value) end,
        experience_level: fn value -> QueryBuilder.ilike_filter(:experience_level, value) end,
        remote_allowed: fn value -> QueryBuilder.boolean_filter(:remote_allowed, value) end,
        location: fn value -> QueryBuilder.ilike_filter(:location, value) end,
        salary_range: &salary_range_filter/1,
        newer_than: &newer_than_filter/1,
        older_than: &older_than_filter/1
      },
      default_alias: :job_posting
    }
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
end
