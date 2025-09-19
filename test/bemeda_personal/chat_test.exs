defmodule BemedaPersonal.ChatTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.ResumesFixtures

  alias BemedaPersonal.Chat
  alias BemedaPersonal.Resumes.Resume
  alias BemedaPersonal.TestUtils
  alias BemedaPersonalWeb.Endpoint
  alias Phoenix.Socket.Broadcast

  defp create_message(_attrs) do
    TestUtils.create_complete_test_setup()
  end

  describe "list_messages/1" do
    setup :create_message

    test "returns all messages for a job application", %{
      job_application: job_application,
      scope: scope
    } do
      [_job_application | messages] = Chat.list_messages(scope, job_application)
      assert length(messages) == 1
    end

    test "includes user's public resume in the list when user has a public resume", %{
      job_application: job_application,
      scope: scope
    } do
      resume_fixture(job_application.user, %{is_public: true})

      result = Chat.list_messages(scope, job_application)

      assert length(result) == 3
      [_job_application, resume | _messages] = result

      assert %Resume{} = resume
      assert resume.is_public == true
      assert resume.user_id == job_application.user.id
    end
  end

  describe "get_message!/1" do
    setup :create_message

    test "returns the message with given id", %{
      message: message,
      scope: scope
    } do
      result = Chat.get_message!(scope, message.id)
      assert result.id == message.id
      assert result.content == message.content
      assert Ecto.assoc_loaded?(result.sender)
      assert Ecto.assoc_loaded?(result.job_application)
    end

    test "raises error when message does not exist", %{scope: scope} do
      non_existent_id = Ecto.UUID.generate()
      assert_raise Ecto.NoResultsError, fn -> Chat.get_message!(scope, non_existent_id) end
    end
  end

  describe "create_message/3" do
    setup [:create_message]

    test "with valid data creates a message", %{
      job_application: job_application,
      user: user,
      scope: scope
    } do
      valid_attrs = %{content: "some content"}

      assert {:ok, %Chat.Message{} = message} =
               Chat.create_message(scope, user, job_application, valid_attrs)

      assert message.content == "some content"
      assert message.job_application_id == job_application.id
      assert message.sender_id == user.id
    end

    test "broadcasts message_created event when a message is created", %{
      job_application: job_application,
      user: user,
      scope: scope
    } do
      message_topic = "messages:job_application:#{job_application.id}"
      Endpoint.subscribe(message_topic)

      valid_attrs = %{content: "new broadcast message"}

      {:ok, message} = Chat.create_message(scope, user, job_application, valid_attrs)

      assert_receive %Broadcast{
        event: "message_created",
        topic: ^message_topic,
        payload: %{message: ^message}
      }
    end

    test "with empty string returns error", %{
      job_application: job_application,
      user: user,
      scope: scope
    } do
      empty_attrs = %{content: ""}

      assert {:error, %Ecto.Changeset{} = changeset} =
               Chat.create_message(scope, user, job_application, empty_attrs)

      assert changeset.errors[:content] == {"cannot be blank", [validation: :required]}
      refute changeset.valid?
    end
  end

  describe "update_message/2" do
    setup [:create_message]

    test "with valid data updates the message", %{message: message, scope: scope} do
      update_attrs = %{content: "updated content"}

      assert {:ok, %Chat.Message{} = updated} = Chat.update_message(scope, message, update_attrs)
      assert updated.content == "updated content"
    end

    test "broadcasts message_updated event when a message is updated", %{
      job_application: job_application,
      message: message,
      scope: scope
    } do
      message_topic = "messages:job_application:#{job_application.id}"
      Endpoint.subscribe(message_topic)

      update_attrs = %{content: "updated broadcast content"}

      {:ok, updated_message} = Chat.update_message(scope, message, update_attrs)

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
      message: message,
      scope: scope
    } do
      assert {:ok, %Chat.Message{}} = Chat.delete_message(scope, message)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_message!(scope, message.id) end
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

  describe "create_message_with_media/3" do
    setup [:create_message]

    test "with valid data creates a message with media asset", %{
      job_application: job_application,
      user: user,
      scope: scope
    } do
      media_data = %{
        "file_name" => "test.mp4",
        "type" => "video/mp4",
        "upload_id" => Ecto.UUID.generate()
      }

      attrs = %{"media_data" => media_data}

      assert {:ok, %Chat.Message{} = message} =
               Chat.create_message_with_media(scope, user, job_application, attrs)

      assert message.media_asset
      assert message.media_asset.file_name == "test.mp4"
      assert message.media_asset.type == "video/mp4"
      assert message.media_asset.upload_id == media_data["upload_id"]
    end

    test "creates a message without media asset when media_data is nil", %{
      job_application: job_application,
      user: user,
      scope: scope
    } do
      attrs = %{}

      assert {:ok, %Chat.Message{} = message} =
               Chat.create_message_with_media(scope, user, job_application, attrs)

      assert message.media_asset == nil
    end

    test "broadcasts message_created event when a message with media is created", %{
      job_application: job_application,
      user: user,
      scope: scope
    } do
      message_topic = "messages:job_application:#{job_application.id}"
      Endpoint.subscribe(message_topic)

      media_data = %{
        "file_name" => "broadcast_test.mp4",
        "type" => "video/mp4",
        "upload_id" => Ecto.UUID.generate()
      }

      attrs = %{"media_data" => media_data}

      {:ok, message} = Chat.create_message_with_media(scope, user, job_application, attrs)

      assert_receive %Broadcast{
        event: "message_created",
        topic: ^message_topic,
        payload: %{message: ^message}
      }
    end
  end
end
