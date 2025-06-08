defmodule BemedaPersonal.Jobs.JobApplicationFilters do
  @moduledoc """
  Filter configuration for job applications.
  """

  import Ecto.Query

  alias BemedaPersonal.Jobs.JobApplicationTag
  alias BemedaPersonal.Jobs.Tag
  alias BemedaPersonal.QueryBuilder

  @spec filter_config() :: QueryBuilder.t()
  def filter_config do
    %QueryBuilder{
      filter_functions: build_filter_functions(),
      default_alias: :job_application,
      joins: build_joins()
    }
  end

  defp build_filter_functions do
    basic_filters()
    |> Map.merge(date_filters())
    |> Map.merge(search_filters())
    |> Map.merge(advanced_filters())
  end

  defp basic_filters do
    %{
      user_id: fn value -> QueryBuilder.exact_match_filter(:user_id, value) end,
      job_posting_id: fn value -> QueryBuilder.exact_match_filter(:job_posting_id, value) end,
      state: fn value -> QueryBuilder.exact_match_filter(:state, value) end
    }
  end

  defp date_filters do
    %{
      date_range: &date_range_filter/1,
      date_from: fn value -> QueryBuilder.date_from_filter(:inserted_at, value) end,
      date_to: fn value -> QueryBuilder.date_to_filter(:inserted_at, value) end,
      newer_than: &newer_than_filter/1,
      older_than: &older_than_filter/1
    }
  end

  defp search_filters do
    %{
      applicant_name: &applicant_name_filter/1,
      job_title: &job_title_filter/1
    }
  end

  defp advanced_filters do
    %{
      company_id: &company_id_filter/1,
      tags: &tags_filter/1
    }
  end

  defp build_joins do
    [
      {:left, :job_posting, :job_posting},
      {:left, :user, :user}
    ]
  end

  defp company_id_filter(company_id) do
    fn _value, dynamic, _alias ->
      dynamic(
        [job_application: ja, job_posting: jp],
        ^dynamic and jp.company_id == ^company_id
      )
    end
  end

  defp date_range_filter(%{from: from_date, to: to_date}) do
    QueryBuilder.date_range_filter(:inserted_at, {from_date, to_date})
  end

  defp applicant_name_filter(name) do
    pattern = "%#{name}%"

    fn _value, dynamic, _alias ->
      dynamic(
        [job_application: ja, user: u],
        ^dynamic and
          (ilike(fragment("concat(?, ' ', ?)", u.first_name, u.last_name), ^pattern) or
             ilike(fragment("concat(?, ' ', ?)", u.last_name, u.first_name), ^pattern))
      )
    end
  end

  defp job_title_filter(title) do
    pattern = "%#{title}%"

    fn _value, dynamic, _alias ->
      dynamic(
        [job_application: ja, job_posting: jp],
        ^dynamic and ilike(jp.title, ^pattern)
      )
    end
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

  defp tags_filter(tags) when is_list(tags) do
    fn _value, dynamic, alias ->
      subquery =
        from(jat in JobApplicationTag,
          join: t in Tag,
          on: t.id == jat.tag_id,
          where: t.name in ^tags,
          group_by: jat.job_application_id,
          select: jat.job_application_id
        )

      dynamic([{^alias, entity}], ^dynamic and field(entity, :id) in subquery(subquery))
    end
  end
end
