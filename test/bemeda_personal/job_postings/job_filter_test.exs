defmodule BemedaPersonal.JobPostings.JobFilterTest do
  use BemedaPersonal.DataCase, async: true

  alias BemedaPersonal.JobPostings.JobFilter

  describe "changeset/2" do
    test "creates a changeset with valid attributes" do
      valid_attrs = %{
        employment_type: "Permanent Position",
        location: "New York",
        position: "Specialist Role",
        remote_allowed: "true",
        search: "Healthcare Jobs"
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

    test "validates position for valid values" do
      Enum.each(["Employee", "Specialist Role", "Leadership Position", ""], fn value ->
        changeset = JobFilter.changeset(%JobFilter{}, %{position: value})
        assert changeset.valid?, "Expected #{value} to be valid"
      end)

      changeset = JobFilter.changeset(%JobFilter{}, %{position: "Invalid"})
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).position
    end

    test "validates profession for valid values" do
      valid_professions = [
        "Medical Practice Assistant (MPA)",
        "Registered Nurse (AKP/DNII/HF/FH)",
        ""
      ]

      Enum.each(valid_professions, fn value ->
        changeset = JobFilter.changeset(%JobFilter{}, %{profession: value})
        assert changeset.valid?, "Expected #{value} to be valid"
      end)

      changeset = JobFilter.changeset(%JobFilter{}, %{profession: "Invalid Profession"})
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).profession
    end

    test "validates department array for valid values" do
      valid_departments = ["Intensive Care", "Emergency Department", "Home Care (Spitex)"]
      valid_changeset = JobFilter.changeset(%JobFilter{}, %{department: valid_departments})
      assert valid_changeset.valid?

      invalid_departments = ["Intensive Care", "Invalid Department"]
      invalid_changeset = JobFilter.changeset(%JobFilter{}, %{department: invalid_departments})
      refute invalid_changeset.valid?
      assert "is invalid" in errors_on(invalid_changeset).department
    end

    test "validates region array for valid values" do
      valid_regions = ["Zurich", "Geneva", "Basel-Stadt"]
      valid_changeset = JobFilter.changeset(%JobFilter{}, %{region: valid_regions})
      assert valid_changeset.valid?

      invalid_regions = ["Zurich", "Invalid Region"]
      invalid_changeset = JobFilter.changeset(%JobFilter{}, %{region: invalid_regions})
      refute invalid_changeset.valid?
      assert "is invalid" in errors_on(invalid_changeset).region
    end

    test "validates language array for valid values" do
      valid_languages = ["German", "English", "French"]
      valid_changeset = JobFilter.changeset(%JobFilter{}, %{language: valid_languages})
      assert valid_changeset.valid?

      invalid_languages = ["German", "Invalid Language"]
      invalid_changeset = JobFilter.changeset(%JobFilter{}, %{language: invalid_languages})
      refute invalid_changeset.valid?
      assert "is invalid" in errors_on(invalid_changeset).language
    end

    test "validates shift_type array for valid values" do
      valid_shifts = ["Day Shift", "Night Shift", "Early Shift"]
      valid_changeset = JobFilter.changeset(%JobFilter{}, %{shift_type: valid_shifts})
      assert valid_changeset.valid?

      invalid_shifts = ["Day Shift", "Invalid Shift"]
      invalid_changeset = JobFilter.changeset(%JobFilter{}, %{shift_type: invalid_shifts})
      refute invalid_changeset.valid?
      assert "is invalid" in errors_on(invalid_changeset).shift_type
    end

    test "validates years_of_experience for valid values" do
      valid_experience = ["Less than 2 years", "2-5 years", "More than 5 years", ""]

      Enum.each(valid_experience, fn value ->
        changeset = JobFilter.changeset(%JobFilter{}, %{years_of_experience: value})
        assert changeset.valid?, "Expected #{value} to be valid"
      end)

      invalid_changeset =
        JobFilter.changeset(%JobFilter{}, %{years_of_experience: "Invalid Experience"})

      refute invalid_changeset.valid?
      assert "is invalid" in errors_on(invalid_changeset).years_of_experience
    end

    test "validates position field accepts all valid position values" do
      valid_positions = ["Employee", "Leadership Position", "Specialist Role", ""]

      Enum.each(valid_positions, fn value ->
        changeset = JobFilter.changeset(%JobFilter{}, %{position: value})
        assert changeset.valid?, "Expected #{value} to be valid"
      end)

      invalid_changeset = JobFilter.changeset(%JobFilter{}, %{position: "Invalid Position"})
      refute invalid_changeset.valid?
      assert "is invalid" in errors_on(invalid_changeset).position
    end

    test "validates currency for valid values" do
      valid_currencies = ["CHF", "EUR", "USD", ""]

      Enum.each(valid_currencies, fn value ->
        changeset = JobFilter.changeset(%JobFilter{}, %{currency: value})
        assert changeset.valid?, "Expected #{value} to be valid"
      end)

      invalid_changeset = JobFilter.changeset(%JobFilter{}, %{currency: "INVALID"})
      refute invalid_changeset.valid?
      assert "is invalid" in errors_on(invalid_changeset).currency
    end

    test "validates salary_min and salary_max for valid ranges" do
      valid_changeset =
        JobFilter.changeset(%JobFilter{}, %{salary_min: 50_000, salary_max: 100_000})

      assert valid_changeset.valid?

      min_invalid_changeset = JobFilter.changeset(%JobFilter{}, %{salary_min: -1000})
      refute min_invalid_changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(min_invalid_changeset).salary_min

      max_invalid_changeset = JobFilter.changeset(%JobFilter{}, %{salary_max: -5000})
      refute max_invalid_changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(max_invalid_changeset).salary_max
    end

    test "validates salary range where min <= max" do
      valid_changeset =
        JobFilter.changeset(%JobFilter{}, %{salary_min: 50_000, salary_max: 100_000})

      assert valid_changeset.valid?

      invalid_changeset =
        JobFilter.changeset(%JobFilter{}, %{salary_min: 100_000, salary_max: 50_000})

      refute invalid_changeset.valid?

      assert "must be less than or equal to salary maximum" in errors_on(invalid_changeset).salary_min
    end

    test "validates search field for any string value" do
      valid_changeset = JobFilter.changeset(%JobFilter{}, %{search: "nurse intensive care"})
      assert valid_changeset.valid?

      empty_changeset = JobFilter.changeset(%JobFilter{}, %{search: ""})
      assert empty_changeset.valid?

      nil_changeset = JobFilter.changeset(%JobFilter{}, %{search: nil})
      assert nil_changeset.valid?

      long_search_changeset =
        JobFilter.changeset(%JobFilter{}, %{
          search: "a very long search term with multiple keywords and phrases"
        })

      assert long_search_changeset.valid?
    end

    test "treats empty values as valid" do
      changeset =
        JobFilter.changeset(%JobFilter{}, %{
          currency: "",
          department: [],
          employment_type: "",
          language: [],
          location: "",
          position: "",
          profession: "",
          region: [],
          remote_allowed: "",
          salary_max: nil,
          salary_min: nil,
          search: "",
          shift_type: [],
          years_of_experience: ""
        })

      assert changeset.valid?
    end
  end

  describe "to_params/1" do
    test "converts string values to appropriate types" do
      filter = %JobFilter{
        employment_type: :"Permanent Position",
        location: "New York",
        position: :"Specialist Role",
        remote_allowed: true,
        search: "Software Developer"
      }

      changeset = JobFilter.changeset(filter, %{})
      params = JobFilter.to_params(changeset)

      assert params[:employment_type] == :"Permanent Position"
      assert params[:location] == "New York"
      assert params[:position] == :"Specialist Role"
      assert params[:remote_allowed] == true
      assert params[:search] == "Software Developer"
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

    test "handles array fields correctly" do
      attrs = %{
        department: ["Intensive Care", "Emergency Department"],
        language: ["German", "English"],
        region: ["Zurich", "Geneva"],
        shift_type: ["Day Shift", "Night Shift"]
      }

      changeset = JobFilter.changeset(%JobFilter{}, attrs)
      params = JobFilter.to_params(changeset)

      assert params[:department] == [:"Intensive Care", :"Emergency Department"]
      assert params[:language] == [:German, :English]
      assert params[:region] == [:Zurich, :Geneva]
      assert params[:shift_type] == [:"Day Shift", :"Night Shift"]
    end

    test "handles salary fields correctly" do
      attrs = %{currency: "CHF", salary_max: 100_000, salary_min: 50_000}

      changeset = JobFilter.changeset(%JobFilter{}, attrs)
      params = JobFilter.to_params(changeset)

      assert params[:currency] == :CHF
      assert params[:salary_min] == 50_000
      assert params[:salary_max] == 100_000
    end

    test "handles search field correctly" do
      changeset = JobFilter.changeset(%JobFilter{}, %{search: "nurse intensive care"})
      params = JobFilter.to_params(changeset)
      assert params[:search] == "nurse intensive care"

      empty_changeset = JobFilter.changeset(%JobFilter{}, %{search: ""})
      empty_params = JobFilter.to_params(empty_changeset)
      refute Map.has_key?(empty_params, :search)

      nil_changeset = JobFilter.changeset(%JobFilter{}, %{search: nil})
      nil_params = JobFilter.to_params(nil_changeset)
      refute Map.has_key?(nil_params, :search)
    end

    test "excludes empty values from filters" do
      filter = %JobFilter{location: "New York", remote_allowed: "", search: ""}
      changeset = JobFilter.changeset(filter, %{})
      params = JobFilter.to_params(changeset)

      refute Map.has_key?(params, :search)
      assert params[:location] == "New York"
      refute Map.has_key?(params, :remote_allowed)
    end

    test "excludes empty arrays from filters" do
      attrs = %{
        department: [],
        language: [],
        profession: "Registered Nurse (AKP/DNII/HF/FH)",
        region: ["Zurich"]
      }

      changeset = JobFilter.changeset(%JobFilter{}, attrs)
      params = JobFilter.to_params(changeset)

      refute Map.has_key?(params, :department)
      refute Map.has_key?(params, :language)
      assert params[:profession] == :"Registered Nurse (AKP/DNII/HF/FH)"
      assert params[:region] == [:Zurich]
    end

    test "excludes nil and empty string values" do
      filter = %JobFilter{
        employment_type: "",
        position: nil,
        location: "New York",
        profession: "",
        remote_allowed: true,
        salary_max: 100_000,
        salary_min: nil,
        search: "Developer"
      }

      changeset = JobFilter.changeset(filter, %{})
      params = JobFilter.to_params(changeset)

      refute Map.has_key?(params, :employment_type)
      refute Map.has_key?(params, :position)
      assert params[:location] == "New York"
      refute Map.has_key?(params, :profession)
      assert params[:remote_allowed] == true
      refute Map.has_key?(params, :salary_min)
      assert params[:salary_max] == 100_000
      assert params[:search] == "Developer"
    end

    test "converts values correctly after applying changeset" do
      changeset =
        JobFilter.changeset(%JobFilter{}, %{
          company_id: "550e8400-e29b-41d4-a716-446655440000",
          department: ["Intensive Care"],
          position: "",
          profession: "Registered Nurse (AKP/DNII/HF/FH)",
          remote_allowed: "true",
          salary_min: 75_000,
          search: "Software Engineer"
        })

      params = JobFilter.to_params(changeset)

      assert params[:company_id] == "550e8400-e29b-41d4-a716-446655440000"
      assert params[:department] == [:"Intensive Care"]
      refute Map.has_key?(params, :position)
      assert params[:profession] == :"Registered Nurse (AKP/DNII/HF/FH)"
      assert params[:remote_allowed] == true
      assert params[:salary_min] == 75_000
      assert params[:search] == "Software Engineer"
    end
  end
end
