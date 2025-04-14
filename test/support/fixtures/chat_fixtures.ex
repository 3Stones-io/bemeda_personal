defmodule BemedaPersonal.ChatFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.Chat` context.
  """

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Chat
  alias BemedaPersonal.Jobs.JobApplication

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

    {:ok, message} = Chat.create_message(user, job_application, message_attrs)

    message
  end
end
