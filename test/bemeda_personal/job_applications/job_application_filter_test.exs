defmodule BemedaPersonal.JobApplications.JobApplicationFilterTest do
  use BemedaPersonal.DataCase, async: true

  alias BemedaPersonal.JobApplications.JobApplicationFilter

  describe "changeset/2" do
    test "creates a changeset with valid attributes" do
      valid_attrs = %{
        applicant_name: "John Doe",
        company_id: "550e8400-e29b-41d4-a716-446655440000",
        date_from: ~D[2023-01-01],
        date_to: ~D[2023-12-31],
        job_posting_id: "550e8400-e29b-41d4-a716-446655440001",
        job_title: "Software Engineer",
        user_id: "550e8400-e29b-41d4-a716-446655440002"
      }

      changeset = JobApplicationFilter.changeset(%JobApplicationFilter{}, valid_attrs)
      assert changeset.valid?
    end

    test "validates date ranges correctly" do
      valid_dates = %{
        date_from: ~D[2023-01-01],
        date_to: ~D[2023-12-31]
      }

      valid_changeset = JobApplicationFilter.changeset(%JobApplicationFilter{}, valid_dates)
      assert valid_changeset.valid?

      invalid_dates = %{
        date_from: ~D[2023-12-31],
        date_to: ~D[2023-01-01]
      }

      invalid_changeset = JobApplicationFilter.changeset(%JobApplicationFilter{}, invalid_dates)
      refute invalid_changeset.valid?

      assert "Start date must be before or equal to end date" in errors_on(invalid_changeset).date_from

      assert "End date must be after or equal to start date" in errors_on(invalid_changeset).date_to
    end

    test "treats empty values as valid" do
      changeset =
        JobApplicationFilter.changeset(%JobApplicationFilter{}, %{
          applicant_name: "",
          company_id: "",
          job_posting_id: "",
          job_title: "",
          user_id: ""
        })

      assert changeset.valid?
    end
  end

  describe "to_params/1" do
    test "excludes nil and empty string values" do
      filter = %JobApplicationFilter{
        applicant_name: "John Doe",
        company_id: "550e8400-e29b-41d4-a716-446655440000",
        job_posting_id: "550e8400-e29b-41d4-a716-446655440001",
        job_title: "",
        user_id: nil
      }

      changeset = JobApplicationFilter.changeset(filter, %{})
      params = JobApplicationFilter.to_params(changeset)

      assert params[:company_id] == "550e8400-e29b-41d4-a716-446655440000"
      assert params[:job_posting_id] == "550e8400-e29b-41d4-a716-446655440001"
      assert params[:applicant_name] == "John Doe"
      refute Map.has_key?(params, :job_title)
      refute Map.has_key?(params, :user_id)
    end

    test "converts dates to strings" do
      changeset =
        JobApplicationFilter.changeset(%JobApplicationFilter{}, %{
          date_from: ~D[2023-01-01],
          date_to: ~D[2023-12-31]
        })

      params = JobApplicationFilter.to_params(changeset)

      assert params[:date_from] == "2023-01-01"
      assert params[:date_to] == "2023-12-31"
    end

    test "handles single dates correctly" do
      changeset1 =
        JobApplicationFilter.changeset(%JobApplicationFilter{}, %{
          date_from: ~D[2023-01-01]
        })

      params1 = JobApplicationFilter.to_params(changeset1)

      assert params1[:date_from] == "2023-01-01"
      refute params1[:date_to]

      changeset2 =
        JobApplicationFilter.changeset(%JobApplicationFilter{}, %{
          date_to: ~D[2023-12-31]
        })

      params2 = JobApplicationFilter.to_params(changeset2)

      refute params2[:date_from]
      assert params2[:date_to] == "2023-12-31"
    end

    test "handles invalid changesets correctly" do
      changeset =
        JobApplicationFilter.changeset(%JobApplicationFilter{}, %{
          date_from: ~D[2023-12-31],
          date_to: ~D[2023-01-01]
        })

      refute changeset.valid?

      params = JobApplicationFilter.to_params(changeset)
      assert params[:date_from] == "2023-12-31"
      assert params[:date_to] == "2023-01-01"
    end
  end
end
