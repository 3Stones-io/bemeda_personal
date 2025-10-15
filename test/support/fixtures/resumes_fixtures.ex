defmodule BemedaPersonal.ResumesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.Resumes` context.
  """

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Resumes
  alias BemedaPersonal.Resumes.Education
  alias BemedaPersonal.Resumes.Resume
  alias BemedaPersonal.Resumes.WorkExperience

  @type attrs :: map()
  @type education :: Education.t()
  @type resume :: Resume.t()
  @type user :: User.t()
  @type work_experience :: WorkExperience.t()

  @doc """
  Generate valid resume attributes.
  """
  @spec valid_resume_attributes(attrs()) :: attrs()
  def valid_resume_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      headline: "Software Engineer",
      summary: "Experienced software engineer with a passion for building web applications.",
      is_public: true,
      contact_email: "contact@example.com",
      phone_number: "+41791234567",
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
      user
      |> Resumes.get_or_create_resume_by_user()
      |> Resumes.update_resume(attrs)

    resume
  end

  @doc """
  Generate valid education attributes.
  """
  @spec valid_education_attributes(attrs()) :: attrs()
  def valid_education_attributes(attrs \\ %{}) do
    base_attrs = %{
      institution: "University of Example",
      degree: "Bachelor of Science",
      field_of_study: "Computer Science",
      start_date: ~D[2015-09-01],
      end_date: ~D[2019-05-31],
      current: false,
      description: "Studied computer science with a focus on software engineering."
    }

    Enum.into(attrs, base_attrs)
  end

  @doc """
  Generate an education entry for a resume.
  """
  @spec education_fixture(resume(), attrs()) :: education()
  def education_fixture(%Resume{} = resume, attrs \\ %{}) do
    attrs = valid_education_attributes(attrs)

    {:ok, education} =
      Resumes.create_or_update_education(
        %Education{},
        resume,
        attrs
      )

    education
  end

  @doc """
  Generate valid work experience attributes.
  """
  @spec valid_work_experience_attributes(attrs()) :: attrs()
  def valid_work_experience_attributes(attrs \\ %{}) do
    base_attrs = %{
      company_name: "Example Corp",
      title: "Software Engineer",
      location: "New York, NY",
      start_date: ~D[2019-06-01],
      end_date: ~D[2022-12-31],
      current: false,
      description: "Developed web applications using Elixir and Phoenix."
    }

    Enum.into(attrs, base_attrs)
  end

  @doc """
  Generate a work experience entry for a resume.
  """
  @spec work_experience_fixture(resume(), attrs()) :: work_experience()
  def work_experience_fixture(%Resume{} = resume, attrs \\ %{}) do
    attrs = valid_work_experience_attributes(attrs)

    {:ok, work_experience} =
      Resumes.create_or_update_work_experience(
        %WorkExperience{},
        resume,
        attrs
      )

    work_experience
  end
end
