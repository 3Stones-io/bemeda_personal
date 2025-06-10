defmodule BemedaPersonal.QueryBuilderTest do
  use BemedaPersonal.DataCase, async: true

  import Ecto.Query

  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.JobPostings.JobPosting
  alias BemedaPersonal.QueryBuilder

  describe "apply_filters/3" do
    test "applies exact match filter" do
      config = %QueryBuilder{
        filter_functions: %{
          company_id: &QueryBuilder.exact_match_filter(:company_id, &1)
        },
        default_alias: :job_posting
      }

      query = QueryBuilder.apply_filters(JobPosting, %{company_id: "123"}, config)

      assert %Ecto.Query{} = query
      assert query.wheres != []
    end

    test "applies ilike filter" do
      config = %QueryBuilder{
        filter_functions: %{
          title: &QueryBuilder.ilike_filter(:title, &1)
        },
        default_alias: :job_posting
      }

      query = QueryBuilder.apply_filters(JobPosting, %{title: "Engineer"}, config)

      assert %Ecto.Query{} = query
      assert query.wheres != []
    end

    test "applies multiple filters" do
      config = %QueryBuilder{
        filter_functions: %{
          company_id: &QueryBuilder.exact_match_filter(:company_id, &1),
          title: &QueryBuilder.ilike_filter(:title, &1)
        },
        default_alias: :job_posting
      }

      filters = %{company_id: "123", title: "Engineer"}
      query = QueryBuilder.apply_filters(JobPosting, filters, config)

      assert %Ecto.Query{} = query
      assert query.wheres != []
    end

    test "ignores unknown filter keys" do
      config = %QueryBuilder{
        filter_functions: %{
          title: &QueryBuilder.ilike_filter(:title, &1)
        },
        default_alias: :job_posting
      }

      filters = %{title: "Engineer", unknown_field: "value"}
      query = QueryBuilder.apply_filters(JobPosting, filters, config)

      assert %Ecto.Query{} = query
      assert query.wheres != []
    end

    test "applies joins when configured" do
      config = %QueryBuilder{
        filter_functions: %{
          title: &QueryBuilder.ilike_filter(:title, &1)
        },
        default_alias: :job_application,
        joins: [
          {:left, :job_posting, :job_posting},
          {:left, :user, :user}
        ]
      }

      query = QueryBuilder.apply_filters(JobApplication, %{title: "Engineer"}, config)

      assert %Ecto.Query{} = query
      assert length(query.joins) == 2
    end

    test "handles empty filters" do
      config = %QueryBuilder{
        filter_functions: %{
          title: &QueryBuilder.ilike_filter(:title, &1)
        },
        default_alias: :job_posting
      }

      query = QueryBuilder.apply_filters(JobPosting, %{}, config)

      assert %Ecto.Query{} = query
      assert Enum.empty?(query.wheres)
    end
  end

  describe "build_dynamic_filter/3" do
    test "builds dynamic filter with single condition" do
      filter_functions = %{
        title: &QueryBuilder.ilike_filter(:title, &1)
      }

      filters = %{title: "Engineer"}
      dynamic = QueryBuilder.build_dynamic_filter(filters, filter_functions, :job_posting)

      assert %Ecto.Query.DynamicExpr{} = dynamic
    end

    test "builds dynamic filter with multiple conditions" do
      filter_functions = %{
        title: &QueryBuilder.ilike_filter(:title, &1),
        company_id: &QueryBuilder.exact_match_filter(:company_id, &1)
      }

      filters = %{title: "Engineer", company_id: "123"}
      dynamic = QueryBuilder.build_dynamic_filter(filters, filter_functions, :job_posting)

      assert %Ecto.Query.DynamicExpr{} = dynamic
    end

    test "ignores unknown filter keys" do
      filter_functions = %{
        title: &QueryBuilder.ilike_filter(:title, &1)
      }

      filters = %{title: "Engineer", unknown: "value"}
      dynamic = QueryBuilder.build_dynamic_filter(filters, filter_functions, :job_posting)

      assert %Ecto.Query.DynamicExpr{} = dynamic
    end
  end

  describe "filter functions" do
    test "exact_match_filter/2" do
      filter_fn = QueryBuilder.exact_match_filter(:company_id, "123")
      dynamic = dynamic(true)

      result = filter_fn.("123", dynamic, :job_posting)

      assert %Ecto.Query.DynamicExpr{} = result
    end

    test "ilike_filter/2" do
      filter_fn = QueryBuilder.ilike_filter(:title, "Engineer")
      dynamic = dynamic(true)

      result = filter_fn.("Engineer", dynamic, :job_posting)

      assert %Ecto.Query.DynamicExpr{} = result
    end

    test "ilike_filter/2 trims whitespace" do
      filter_fn = QueryBuilder.ilike_filter(:title, "  Engineer  ")
      dynamic = dynamic(true)

      result = filter_fn.("  Engineer  ", dynamic, :job_posting)

      assert %Ecto.Query.DynamicExpr{} = result
    end

    test "ilike_filter/2 handles atoms" do
      filter_fn = QueryBuilder.ilike_filter(:experience_level, :Senior)
      dynamic = dynamic(true)

      result = filter_fn.(:Senior, dynamic, :job_posting)

      assert %Ecto.Query.DynamicExpr{} = result
    end

    test "boolean_filter/2 with true" do
      filter_fn = QueryBuilder.boolean_filter(:remote_allowed, true)
      dynamic = dynamic(true)

      result = filter_fn.(true, dynamic, :job_posting)

      assert %Ecto.Query.DynamicExpr{} = result
    end

    test "boolean_filter/2 with false" do
      filter_fn = QueryBuilder.boolean_filter(:remote_allowed, false)
      dynamic = dynamic(true)

      result = filter_fn.(false, dynamic, :job_posting)

      assert %Ecto.Query.DynamicExpr{} = result
    end

    test "numeric_range_filter/3" do
      filter_fn = QueryBuilder.numeric_range_filter(:salary_min, :salary_max, {50_000, 100_000})
      dynamic = dynamic(true)

      result = filter_fn.({50_000, 100_000}, dynamic, :job_posting)

      assert %Ecto.Query.DynamicExpr{} = result
    end

    test "in_filter/2 with list of values" do
      filter_fn = QueryBuilder.in_filter(:status, ["active", "pending"])
      dynamic = dynamic(true)

      result = filter_fn.(["active", "pending"], dynamic, :job_posting)

      assert %Ecto.Query.DynamicExpr{} = result
    end

    test "date_from_filter/2 with valid date string" do
      filter_fn = QueryBuilder.date_from_filter(:inserted_at, "2023-01-01")
      dynamic = dynamic(true)

      result = filter_fn.("2023-01-01", dynamic, :job_posting)

      assert %Ecto.Query.DynamicExpr{} = result
    end

    test "date_from_filter/2 with Date struct" do
      date = ~D[2023-01-01]
      filter_fn = QueryBuilder.date_from_filter(:inserted_at, date)
      dynamic = dynamic(true)

      result = filter_fn.(date, dynamic, :job_posting)

      assert %Ecto.Query.DynamicExpr{} = result
    end

    test "date_from_filter/2 with nil date returns unchanged dynamic" do
      filter_fn = QueryBuilder.date_from_filter(:inserted_at, nil)
      dynamic = dynamic(true)

      result = filter_fn.(nil, dynamic, :job_posting)

      assert result == dynamic
    end

    test "date_to_filter/2 with valid date string" do
      filter_fn = QueryBuilder.date_to_filter(:inserted_at, "2023-12-31")
      dynamic = dynamic(true)

      result = filter_fn.("2023-12-31", dynamic, :job_posting)

      assert %Ecto.Query.DynamicExpr{} = result
    end

    test "date_to_filter/2 with Date struct" do
      date = ~D[2023-12-31]
      filter_fn = QueryBuilder.date_to_filter(:inserted_at, date)
      dynamic = dynamic(true)

      result = filter_fn.(date, dynamic, :job_posting)

      assert %Ecto.Query.DynamicExpr{} = result
    end

    test "date_to_filter/2 with nil date returns unchanged dynamic" do
      filter_fn = QueryBuilder.date_to_filter(:inserted_at, nil)
      dynamic = dynamic(true)

      result = filter_fn.(nil, dynamic, :job_posting)

      assert result == dynamic
    end

    test "date_range_filter/2 with valid date range" do
      filter_fn = QueryBuilder.date_range_filter(:inserted_at, {"2023-01-01", "2023-12-31"})
      dynamic = dynamic(true)

      result = filter_fn.({"2023-01-01", "2023-12-31"}, dynamic, :job_posting)

      assert %Ecto.Query.DynamicExpr{} = result
    end

    test "date_range_filter/2 with Date structs" do
      from_date = ~D[2023-01-01]
      to_date = ~D[2023-12-31]
      filter_fn = QueryBuilder.date_range_filter(:inserted_at, {from_date, to_date})
      dynamic = dynamic(true)

      result = filter_fn.({from_date, to_date}, dynamic, :job_posting)

      assert %Ecto.Query.DynamicExpr{} = result
    end

    test "date_range_filter/2 with nil dates returns unchanged dynamic" do
      filter_fn = QueryBuilder.date_range_filter(:inserted_at, {nil, nil})
      dynamic = dynamic(true)

      result = filter_fn.({nil, nil}, dynamic, :job_posting)

      assert result == dynamic
    end

    test "subquery_filter/3" do
      filter_fn = QueryBuilder.subquery_filter(JobPosting, :company_id, "123")
      dynamic = dynamic(true)

      result = filter_fn.("123", dynamic, :job_application)

      assert %Ecto.Query.DynamicExpr{} = result
    end
  end
end
