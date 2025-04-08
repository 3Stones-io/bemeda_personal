defmodule BemedaPersonal.JobsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.Jobs` context.
  """

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs

  @type attrs :: map()
  @type company :: Companies.Company.t()
  @type job_application :: Jobs.JobApplication.t()
  @type job_posting :: Jobs.JobPosting.t()
  @type user :: User.t()
  @type message :: Jobs.Message.t()

  @spec job_posting_fixture(company(), attrs()) :: job_posting()
  def job_posting_fixture(%Companies.Company{} = company, attrs \\ %{}) do
    job_posting_attrs =
      Enum.into(attrs, %{
        currency: "USD",
        description: "some description",
        employment_type: "some employment_type",
        experience_level: "some experience_level",
        location: "some location",
        remote_allowed: true,
        salary_max: 42_000,
        salary_min: 42_000,
        title: "some title"
      })

    {:ok, job_posting} = Jobs.create_job_posting(company, job_posting_attrs)

    job_posting
  end

  @spec job_application_fixture(user(), job_posting(), attrs()) :: job_application()
  def job_application_fixture(%User{} = user, %Jobs.JobPosting{} = job_posting, attrs \\ %{}) do
    job_application_attrs =
      Enum.into(attrs, %{
        cover_letter: "some cover letter"
      })

    {:ok, job_application} = Jobs.create_job_application(user, job_posting, job_application_attrs)

    job_application
  end

  @spec message_fixture(user(), job_application(), attrs()) :: message()
  def message_fixture(%User{} = user, %Jobs.JobApplication{} = job_application, attrs \\ %{}) do
    message_attrs =
      Enum.into(attrs, %{
        content: "some test message content"
      })

    {:ok, message} = Jobs.create_message(user, job_application, message_attrs)

    message
  end
end
