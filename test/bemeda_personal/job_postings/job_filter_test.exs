defmodule BemedaPersonal.JobPostings.JobFilterTest do
  use BemedaPersonal.DataCase, async: true

  alias BemedaPersonal.JobPostings.JobFilter

  describe "changeset/2" do
    test "creates a changeset with valid attributes" do
      valid_attrs = %{
        title: "Developer",
        location: "New York",
        remote_allowed: "true",
        employment_type: "Permanent Position",
        experience_level: "Senior"
      }

      changeset = JobFilter.changeset(%JobFilter{}, valid_attrs)
      assert changeset.valid?
    end

    test "validates remote_allowed for valid values" do
      changeset_1 = JobFilter.changeset(%JobFilter{}, %{remote_allowed: "true"})
      assert changeset_1.valid?

      changeset_2 = JobFilter.changeset(%JobFilter{}, %{remote_allowed: "false"})
      assert changeset_2.valid?

      changeset_3 = JobFilter.changeset(%JobFilter{}, %{remote_allowed: ""})
      assert changeset_3.valid?
    end

    test "validates employment_type for valid values" do
      Enum.each(
        ["Floater", "Permanent Position", "Staff Pool", "Temporary Assignment", ""],
        fn value ->
          changeset = JobFilter.changeset(%JobFilter{}, %{employment_type: value})
          assert changeset.valid?, "Expected #{value} to be valid"
        end
      )

      changeset = JobFilter.changeset(%JobFilter{}, %{employment_type: "Invalid"})
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).employment_type
    end

    test "validates experience_level for valid values" do
      Enum.each(["Junior", "Mid-level", "Senior", "Lead", "Executive", ""], fn value ->
        changeset = JobFilter.changeset(%JobFilter{}, %{experience_level: value})
        assert changeset.valid?, "Expected #{value} to be valid"
      end)

      changeset = JobFilter.changeset(%JobFilter{}, %{experience_level: "Invalid"})
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).experience_level
    end

    test "treats empty values as valid" do
      changeset =
        JobFilter.changeset(%JobFilter{}, %{
          title: "",
          location: "",
          remote_allowed: "",
          employment_type: "",
          experience_level: ""
        })

      assert changeset.valid?
    end
  end

  describe "to_params/1" do
    test "converts string values to appropriate types" do
      filter = %JobFilter{
        title: "Developer",
        location: "New York",
        remote_allowed: true,
        employment_type: "Permanent Position",
        experience_level: "Senior"
      }

      changeset = JobFilter.changeset(filter, %{})
      params = JobFilter.to_params(changeset)

      assert params[:title] == "Developer"
      assert params[:location] == "New York"
      assert params[:remote_allowed] == true
      assert params[:employment_type] == "Permanent Position"
      assert params[:experience_level] == "Senior"
    end

    test "converts remote_allowed from string to boolean" do
      changeset_1 = JobFilter.changeset(%JobFilter{}, %{remote_allowed: "true"})
      params_1 = JobFilter.to_params(changeset_1)
      assert params_1[:remote_allowed] == true

      changeset_2 = JobFilter.changeset(%JobFilter{}, %{remote_allowed: "false"})
      params_2 = JobFilter.to_params(changeset_2)
      assert params_2[:remote_allowed] == false

      changeset_3 = JobFilter.changeset(%JobFilter{}, %{remote_allowed: ""})
      params_3 = JobFilter.to_params(changeset_3)
      refute Map.has_key?(params_3, :remote_allowed)

      changeset_4 = JobFilter.changeset(%JobFilter{}, %{remote_allowed: nil})
      params_4 = JobFilter.to_params(changeset_4)
      refute Map.has_key?(params_4, :remote_allowed)
    end

    test "excludes empty values from filters" do
      filter = %JobFilter{title: "", location: "New York", remote_allowed: ""}
      changeset = JobFilter.changeset(filter, %{})
      params = JobFilter.to_params(changeset)

      refute Map.has_key?(params, :title)
      assert params[:location] == "New York"
      refute Map.has_key?(params, :remote_allowed)
    end

    test "excludes nil and empty string values" do
      filter = %JobFilter{
        title: "Developer",
        location: "New York",
        remote_allowed: true,
        employment_type: "",
        experience_level: nil
      }

      changeset = JobFilter.changeset(filter, %{})
      params = JobFilter.to_params(changeset)

      assert params[:title] == "Developer"
      assert params[:location] == "New York"
      assert params[:remote_allowed] == true
      refute Map.has_key?(params, :employment_type)
      refute Map.has_key?(params, :experience_level)
    end

    test "converts values correctly after applying changeset" do
      changeset =
        JobFilter.changeset(%JobFilter{}, %{
          title: "Engineer",
          remote_allowed: "true",
          company_id: "550e8400-e29b-41d4-a716-446655440000",
          experience_level: ""
        })

      params = JobFilter.to_params(changeset)

      assert params[:title] == "Engineer"
      assert params[:remote_allowed] == true
      assert params[:company_id] == "550e8400-e29b-41d4-a716-446655440000"
      refute Map.has_key?(params, :experience_level)
    end
  end
end
