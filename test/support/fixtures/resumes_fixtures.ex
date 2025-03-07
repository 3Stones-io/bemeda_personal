defmodule BemedaPersonal.ResumesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.Resumes` context.
  """

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Resumes.Education
  alias BemedaPersonal.Resumes.Resume
  alias BemedaPersonal.Resumes.WorkExperience

  # Custom types for type specifications
  @type user :: User.t()
  @type resume :: Resume.t()
  @type education :: Education.t()
  @type work_experience :: WorkExperience.t()
  @type attrs :: map()

  @doc """
  Generate valid resume attributes.
  """
  @spec valid_resume_attributes(attrs()) :: attrs()
  def valid_resume_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      headline: "Software Engineer",
      summary: "Experienced software engineer with a passion for building web applications.",
      location: "New York, NY",
      is_public: true,
      contact_email: "contact@example.com",
      phone_number: "123-456-7890",
      website_url: "https://example.com"
    })
  end

  @doc """
  Generate a resume for a user.
  """
  @spec resume_fixture(user(), attrs()) :: resume()
  def resume_fixture(%User{} = user, attrs \\ %{}) do
    attrs = valid_resume_attributes(attrs)

    {:ok, resume} =
      %Resume{}
      |> Resume.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:user, user)
      |> BemedaPersonal.Repo.insert()

    # Reload the resume to ensure consistent test results
    BemedaPersonal.Repo.get(Resume, resume.id)
  end

  @doc """
  Generate valid education attributes.
  """
  @spec valid_education_attributes(attrs()) :: attrs()
  def valid_education_attributes(attrs \\ %{}) do
    # Default attributes
    base_attrs = %{
      institution: "University of Example",
      degree: "Bachelor of Science",
      field_of_study: "Computer Science",
      start_date: ~D[2015-09-01],
      end_date: ~D[2019-05-31],
      current: false,
      description: "Studied computer science with a focus on software engineering."
    }

    # Merge provided attributes with defaults
    attrs = Enum.into(attrs, base_attrs)

    # Handle current education (end_date should be nil)
    if attrs.current == true do
      Map.put(attrs, :end_date, nil)
    else
      ensure_valid_date_range(attrs)
    end
  end

  # Helper function to ensure end_date is after start_date
  @spec ensure_valid_date_range(attrs()) :: attrs()
  defp ensure_valid_date_range(attrs) do
    case {Map.get(attrs, :start_date), Map.get(attrs, :end_date)} do
      {%Date{} = start_date, %Date{} = end_date} ->
        if Date.compare(end_date, start_date) == :lt do
          # If end_date is before start_date, set it to 4 years after start_date
          Map.put(attrs, :end_date, Date.add(start_date, 365 * 4))
        else
          attrs
        end

      {_start_date_unused, _end_date_unused} ->
        attrs
    end
  end

  @doc """
  Generate an education entry for a resume.
  """
  @spec education_fixture(resume(), attrs()) :: education()
  def education_fixture(%Resume{} = resume, attrs \\ %{}) do
    attrs = valid_education_attributes(attrs)

    {:ok, education} =
      %Education{}
      |> Education.changeset(Map.put(attrs, :resume_id, resume.id))
      |> BemedaPersonal.Repo.insert()

    education
  end

  @doc """
  Generate valid work experience attributes.
  """
  @spec valid_work_experience_attributes(attrs()) :: attrs()
  def valid_work_experience_attributes(attrs \\ %{}) do
    # Default attributes
    base_attrs = %{
      company_name: "Example Corp",
      title: "Software Engineer",
      location: "New York, NY",
      start_date: ~D[2019-06-01],
      end_date: ~D[2022-12-31],
      current: false,
      description: "Developed web applications using Elixir and Phoenix."
    }

    # Merge provided attributes with defaults
    attrs = Enum.into(attrs, base_attrs)

    # Handle current job (end_date should be nil)
    if attrs.current == true do
      Map.put(attrs, :end_date, nil)
    else
      ensure_valid_work_date_range(attrs)
    end
  end

  # Helper function to ensure end_date is after start_date for work experience
  @spec ensure_valid_work_date_range(attrs()) :: attrs()
  defp ensure_valid_work_date_range(attrs) do
    case {Map.get(attrs, :start_date), Map.get(attrs, :end_date)} do
      {%Date{} = start_date, %Date{} = end_date} ->
        if Date.compare(end_date, start_date) == :lt do
          # If end_date is before start_date, set it to 3 years after start_date
          Map.put(attrs, :end_date, Date.add(start_date, 365 * 3))
        else
          attrs
        end

      {_start_date_unused, _end_date_unused} ->
        attrs
    end
  end

  @doc """
  Generate a work experience entry for a resume.
  """
  @spec work_experience_fixture(resume(), attrs()) :: work_experience()
  def work_experience_fixture(%Resume{} = resume, attrs \\ %{}) do
    attrs = valid_work_experience_attributes(attrs)

    {:ok, work_experience} =
      %WorkExperience{}
      |> WorkExperience.changeset(Map.put(attrs, :resume_id, resume.id))
      |> BemedaPersonal.Repo.insert()

    work_experience
  end
end
