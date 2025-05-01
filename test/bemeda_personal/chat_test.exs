defmodule BemedaPersonal.ChatTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.ChatFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures

  alias BemedaPersonal.Chat
  alias BemedaPersonalWeb.Endpoint
  alias Phoenix.Socket.Broadcast

  defp create_message(_attrs) do
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
    setup :create_message

    test "returns all messages for a job application", %{
      job_application: job_application
    } do
      [_job_application | messages] = Chat.list_messages(job_application)
      assert length(messages) == 1
    end
  end

  describe "get_message!/1" do
    setup :create_message

    test "returns the message with given id", %{
      message: message
    } do
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
    setup [:create_message]

    test "with valid data creates a message", %{
      job_application: job_application,
      user: user
    } do
      valid_attrs = %{content: "some content"}

      assert {:ok, %Chat.Message{} = message} =
               Chat.create_message(user, job_application, valid_attrs)

      assert message.content == "some content"
      assert message.job_application_id == job_application.id
      assert message.sender_id == user.id
    end

    test "broadcasts new_message event when a message is created", %{
      job_application: job_application,
      user: user
    } do
      message_topic = "messages:job_application:#{job_application.id}"
      Endpoint.subscribe(message_topic)

      valid_attrs = %{content: "new broadcast message"}

      {:ok, message} = Chat.create_message(user, job_application, valid_attrs)

      assert_receive %Broadcast{
        event: "new_message",
        topic: ^message_topic,
        payload: %{message: ^message}
      }
    end
  end

  describe "update_message/2" do
    setup [:create_message]

    test "with valid data updates the message", %{message: message} do
      update_attrs = %{content: "updated content"}

      assert {:ok, %Chat.Message{} = updated} = Chat.update_message(message, update_attrs)
      assert updated.content == "updated content"
    end

    test "broadcasts message_updated event when a message is updated", %{
      job_application: job_application,
      message: message
    } do
      message_topic = "messages:job_application:#{job_application.id}"
      Endpoint.subscribe(message_topic)

      update_attrs = %{content: "updated broadcast content"}

      {:ok, updated_message} = Chat.update_message(message, update_attrs)

      assert_receive %Broadcast{
        event: "message_updated",
        topic: ^message_topic,
        payload: %{message: ^updated_message}
      }
    end
  end

  describe "delete_message/1" do
    setup :create_message

    test "successfully deletes the message", %{
      message: message
    } do
      assert {:ok, %Chat.Message{}} = Chat.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_message!(message.id) end
    end
  end

  describe "change_message/2" do
    setup :create_message

    test "returns a message changeset", %{
      message: message
    } do
      assert %Ecto.Changeset{} = Chat.change_message(message)
    end

    test "applies changes correctly", %{
      message: message
    } do
      changes = %{content: "new content"}

      changeset = Chat.change_message(message, changes)
      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :content) == "new content"
    end
  end

  describe "get_message_by_upload_id/1" do
    setup do
      user = user_fixture()
      company = company_fixture(user)
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      message =
        message_fixture(user, job_application, %{
          content: nil,
          mux_data: %{
            "asset_id" => "asset_123",
            "playback_id" => "playback_123",
            "type" => "video",
            "upload_id" => "test_upload_123"
          }
        })

      %{
        job_application: job_application,
        message: message,
        user: user
      }
    end

    test "returns the message with given upload id", %{message: message} do
      result = Chat.get_message_by_upload_id("test_upload_123")
      assert result.id == message.id
      assert result.mux_data.upload_id == "test_upload_123"
      assert Ecto.assoc_loaded?(result.sender)
      assert Ecto.assoc_loaded?(result.job_application)
    end

    test "returns nil when no message with the upload id exists" do
      refute Chat.get_message_by_upload_id("non_existent_upload_id")
    end
  end
end
