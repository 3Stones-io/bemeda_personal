defmodule BemedaPersonal.ChatFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.Chat` context.
  """

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Chat
  alias BemedaPersonal.JobApplications.JobApplication

  @type attrs :: map()
  @type job_application :: JobApplication.t()
  @type message :: Chat.message()
  @type user :: User.t()

  @spec message_fixture(user(), job_application(), attrs()) :: message()
  def message_fixture(%User{} = user, %JobApplication{} = job_application, attrs \\ %{}) do
    message_attrs =
      Enum.into(attrs, %{
        content: "some test message content"
      })

    # Create scope for user access based on user type
    job_application = BemedaPersonal.Repo.preload(job_application, job_posting: [:company])
    user_scope = Scope.for_user(user)

    scope =
      case user.user_type do
        :employer ->
          # For employers, add their company to the scope
          company = job_application.job_posting.company
          Scope.put_company(user_scope, company)

        :job_seeker ->
          # For job seekers, just user scope is enough if they own the application
          user_scope
      end

    {:ok, message} = Chat.create_message(scope, user, job_application, message_attrs)

    message
  end
end
