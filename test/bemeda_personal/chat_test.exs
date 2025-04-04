defmodule BemedaPersonal.ChatTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.ChatFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures

  alias BemedaPersonal.Chat

  setup do
    user = user_fixture()
    company = company_fixture(user)
    job_posting = job_posting_fixture(company)
    job_application = job_application_fixture(user, job_posting)
    message = message_fixture(user, job_application)

    %{
      company: company,
      job_application: job_application,
      job_posting: job_posting,
      message: message,
      user: user
    }
  end

  describe "list_messages/1" do
    test "returns all messages for a job application", %{
      job_application: job_application,
      message: message
    } do
      messages = Chat.list_messages(job_application)
      assert length(messages) == 1
      assert Enum.at(messages, 0).id == message.id
      assert Enum.at(messages, 0).content == message.content
      assert Ecto.assoc_loaded?(Enum.at(messages, 0).sender)
    end

    test "returns empty list when job application has no messages", %{
      user: user,
      job_posting: job_posting
    } do
      new_job_application =
        job_application_fixture(user, job_posting, %{cover_letter: "no messages"})

      assert new_job_application
             |> Chat.list_messages()
             |> Enum.empty?()
    end
  end

  describe "get_message!/1" do
    test "returns the message with given id", %{message: message} do
      result = Chat.get_message!(message.id)
      assert result.id == message.id
      assert result.content == message.content
      assert Ecto.assoc_loaded?(result.sender)
      assert Ecto.assoc_loaded?(result.job_application)
    end

    test "raises error when message does not exist" do
      non_existent_id = Ecto.UUID.generate()
      assert_raise Ecto.NoResultsError, fn -> Chat.get_message!(non_existent_id) end
    end
  end

  describe "create_message/3" do
    test "with valid data creates a message", %{
      user: user,
      job_application: job_application
    } do
      valid_attrs = %{content: "some content", media_type: "text"}

      assert {:ok, %Chat.Message{} = message} =
               Chat.create_message(user, job_application, valid_attrs)

      assert message.content == "some content"
      assert message.media_type == "text"
      assert message.sender_id == user.id
      assert message.job_application_id == job_application.id
    end

    test "with invalid data returns error changeset", %{
      user: user,
      job_application: job_application
    } do
      invalid_attrs = %{content: nil, media_type: "invalid"}

      assert {:error, %Ecto.Changeset{}} =
               Chat.create_message(user, job_application, invalid_attrs)
    end
  end

  describe "update_message/2" do
    test "with valid data updates the message", %{message: message} do
      update_attrs = %{content: "updated content", media_type: "image"}

      assert {:ok, %Chat.Message{} = updated} = Chat.update_message(message, update_attrs)
      assert updated.content == "updated content"
      assert updated.media_type == "image"
    end

    test "with invalid data returns error changeset", %{message: message} do
      invalid_attrs = %{content: nil, media_type: "invalid"}
      assert {:error, %Ecto.Changeset{}} = Chat.update_message(message, invalid_attrs)
      assert message.id == Chat.get_message!(message.id).id
    end
  end

  describe "delete_message/1" do
    test "successfully deletes the message", %{message: message} do
      assert {:ok, %Chat.Message{}} = Chat.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_message!(message.id) end
    end
  end

  describe "change_message/2" do
    test "returns a message changeset", %{message: message} do
      assert %Ecto.Changeset{} = Chat.change_message(message)
    end

    test "applies changes correctly", %{message: message} do
      changes = %{content: "new content"}
      changeset = Chat.change_message(message, changes)
      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :content) == "new content"
    end
  end
end
