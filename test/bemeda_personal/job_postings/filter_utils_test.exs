defmodule BemedaPersonal.JobPostings.FilterUtilsTest do
  use BemedaPersonal.DataCase, async: true

  alias BemedaPersonal.JobPostings.FilterUtils
  alias BemedaPersonal.JobPostings.JobFilter

  describe "changeset_to_params/1" do
    test "converts a valid changeset to parameters" do
      attrs = %{
        employment_type: "Permanent Position",
        location: "Zurich",
        remote_allowed: true,
        title: "Developer"
      }

      params =
        %JobFilter{}
        |> JobFilter.changeset(attrs)
        |> FilterUtils.changeset_to_params()

      assert params[:employment_type] == :"Permanent Position"
      assert params[:location] == "Zurich"
      assert params[:remote_allowed] == true
      assert params[:title] == "Developer"
    end

    test "excludes nil values" do
      attrs = %{location: nil, remote_allowed: true, title: "Developer"}

      params =
        %JobFilter{}
        |> JobFilter.changeset(attrs)
        |> FilterUtils.changeset_to_params()

      refute Map.has_key?(params, :location)
      assert params[:remote_allowed] == true
      assert params[:title] == "Developer"
    end

    test "excludes empty string values" do
      attrs = %{employment_type: "Permanent Position", location: "", title: "Developer"}

      params =
        %JobFilter{}
        |> JobFilter.changeset(attrs)
        |> FilterUtils.changeset_to_params()

      refute Map.has_key?(params, :location)
      assert params[:employment_type] == :"Permanent Position"
      assert params[:title] == "Developer"
    end

    test "excludes empty arrays" do
      attrs = %{
        department: [],
        language: [],
        region: ["Zurich"],
        title: "Developer"
      }

      params =
        %JobFilter{}
        |> JobFilter.changeset(attrs)
        |> FilterUtils.changeset_to_params()

      refute Map.has_key?(params, :department)
      assert params[:title] == "Developer"
      assert params[:region] == [:Zurich]
      refute Map.has_key?(params, :language)
    end

    test "handles array fields with values" do
      attrs = %{
        department: ["Intensive Care", "Emergency Department"],
        language: ["German", "English"],
        region: ["Zurich", "Geneva"]
      }

      params =
        %JobFilter{}
        |> JobFilter.changeset(attrs)
        |> FilterUtils.changeset_to_params()

      assert params[:department] == [:"Intensive Care", :"Emergency Department"]
      assert params[:region] == [:Zurich, :Geneva]
      assert params[:language] == [:German, :English]
    end
  end
end
