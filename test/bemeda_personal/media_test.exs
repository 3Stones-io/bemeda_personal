defmodule BemedaPersonal.MediaTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.MediaFixtures

  alias BemedaPersonal.Media
  alias BemedaPersonal.Media.MediaAsset
  alias BemedaPersonal.TestUtils
  alias BemedaPersonalWeb.Endpoint
  alias Phoenix.Socket.Broadcast

  defp create_test_data(_context) do
    TestUtils.create_complete_test_setup()
  end

  describe "list_media_assets/0" do
    setup [:create_test_data]

    test "returns all media assets accessible to scope", %{
      job_application: job_application,
      job_posting: job_posting,
      message: message,
      scope: scope
    } do
      media_asset1 = media_asset_fixture(job_application, %{})
      media_asset2 = media_asset_fixture(job_posting, %{})
      media_asset3 = media_asset_fixture(message, %{})

      assert media_assets = Media.list_media_assets(scope)
      # Employer scope should see job application and job posting media assets
      assert Enum.find(media_assets, &(&1.id == media_asset1.id))
      assert Enum.find(media_assets, &(&1.id == media_asset2.id))
      # Message media assets have no company association, so not visible to employer scope
      refute Enum.find(media_assets, &(&1.id == media_asset3.id))
    end
  end

  describe "get_media_asset/2" do
    setup [:create_test_data]

    test "returns the media asset with given id", %{
      job_application: job_application,
      scope: scope
    } do
      media_asset = media_asset_fixture(job_application, %{})
      fetched_asset = Media.get_media_asset(scope, media_asset.id)
      assert fetched_asset.id == media_asset.id
      assert fetched_asset.file_name == media_asset.file_name
    end

    test "returns nil when media asset with id does not exist", %{scope: scope} do
      refute Media.get_media_asset(scope, Ecto.UUID.generate())
    end
  end

  describe "get_media_asset_by_message_id/1" do
    setup [:create_test_data]

    test "returns the media asset for a given message_id", %{message: message} do
      media_asset = media_asset_fixture(message, %{file_name: "message_attachment.pdf"})

      fetched_asset = Media.get_media_asset_by_message_id(message.id)

      assert fetched_asset.id == media_asset.id
      assert fetched_asset.message_id == message.id
      assert fetched_asset.file_name == "message_attachment.pdf"
    end

    test "returns nil when no media asset exists for the message_id" do
      non_existent_message_id = Ecto.UUID.generate()
      refute Media.get_media_asset_by_message_id(non_existent_message_id)
    end

    test "returns nil when message_id is nil" do
      refute Media.get_media_asset_by_message_id(nil)
    end
  end

  describe "create_media_asset/2" do
    setup [:create_test_data]

    test "with valid data creates a media asset for job application", %{
      job_application: job_application
    } do
      valid_attrs = %{
        file_name: "app_file.mp4",
        status: :uploaded,
        type: "video/mp4"
      }

      assert {:ok, %MediaAsset{} = media_asset} =
               Media.create_media_asset(job_application, valid_attrs)

      assert media_asset.file_name == "app_file.mp4"
      assert media_asset.status == :uploaded
      assert media_asset.type == "video/mp4"
      assert media_asset.job_application_id == job_application.id
    end

    test "with valid data creates a media asset for job posting", %{job_posting: job_posting} do
      valid_attrs = %{
        file_name: "posting_file.pdf",
        status: :uploaded,
        type: "application/pdf"
      }

      assert {:ok, %MediaAsset{} = media_asset} =
               Media.create_media_asset(job_posting, valid_attrs)

      assert media_asset.file_name == "posting_file.pdf"
      assert media_asset.status == :uploaded
      assert media_asset.type == "application/pdf"
      assert media_asset.job_posting_id == job_posting.id
    end

    test "with valid data creates a media asset for message", %{message: message} do
      valid_attrs = %{
        file_name: "message_file.png",
        status: :uploaded,
        type: "image/png"
      }

      assert {:ok, %MediaAsset{} = media_asset} = Media.create_media_asset(message, valid_attrs)
      assert media_asset.file_name == "message_file.png"
      assert media_asset.status == :uploaded
      assert media_asset.type == "image/png"
      assert media_asset.message_id == message.id
    end

    test "with valid data creates a media asset for user" do
      user = user_fixture()

      valid_attrs = %{
        file_name: "profile_picture.jpg",
        status: :uploaded,
        type: "image/jpeg"
      }

      assert {:ok, %MediaAsset{} = media_asset} = Media.create_media_asset(user, valid_attrs)
      assert media_asset.file_name == "profile_picture.jpg"
      assert media_asset.status == :uploaded
      assert media_asset.type == "image/jpeg"
      assert media_asset.user_id == user.id
    end
  end

  describe "update_media_asset/2" do
    setup [:create_test_data]

    test "with valid data updates the media asset", %{job_application: job_application} do
      media_asset = media_asset_fixture(job_application, %{})

      update_attrs = %{
        file_name: "updated_file.mp4",
        status: :failed,
        type: "video/mpeg"
      }

      assert {:ok, %MediaAsset{} = updated_media_asset} =
               Media.update_media_asset(media_asset, update_attrs)

      assert updated_media_asset.file_name == "updated_file.mp4"
      assert updated_media_asset.status == :failed
      assert updated_media_asset.type == "video/mpeg"
    end

    test "allows updating fields with nil values", %{
      job_application: job_application,
      scope: scope
    } do
      media_asset = media_asset_fixture(job_application, %{})
      invalid_attrs = %{file_name: nil, type: nil}

      {:ok, updated_media_asset} = Media.update_media_asset(media_asset, invalid_attrs)
      refute updated_media_asset.file_name
      fetched_media_asset = Media.get_media_asset(scope, media_asset.id)
      assert fetched_media_asset.id == updated_media_asset.id
      refute fetched_media_asset.file_name
    end

    test "broadcasts to company topic when updating company media asset", %{
      company: company
    } do
      media_asset = media_asset_fixture(company, %{})
      topic = "company:#{company.id}:media_assets"
      Endpoint.subscribe(topic)

      {:ok, updated_media_asset} = Media.update_media_asset(media_asset, %{status: :failed})

      assert_receive %Broadcast{
        event: "media_asset_updated",
        topic: ^topic,
        payload: %{media_asset: ^updated_media_asset, company: ^company}
      }
    end

    test "broadcasts to job_application topic when updating job application media asset", %{
      job_application: job_application
    } do
      media_asset = media_asset_fixture(job_application, %{})
      topic = "job_application:#{job_application.id}:media_assets"
      Endpoint.subscribe(topic)

      {:ok, updated_media_asset} = Media.update_media_asset(media_asset, %{status: :failed})

      assert_receive %Broadcast{
        event: "media_asset_updated",
        topic: ^topic,
        payload: %{media_asset: ^updated_media_asset, job_application: ^job_application}
      }
    end

    test "broadcasts to job_posting topic when updating job posting media asset", %{
      job_posting: job_posting
    } do
      media_asset = media_asset_fixture(job_posting, %{})
      topic = "job_posting:#{job_posting.id}:media_assets"
      Endpoint.subscribe(topic)

      {:ok, updated_media_asset} = Media.update_media_asset(media_asset, %{status: :failed})

      assert_receive %Broadcast{
        event: "media_asset_updated",
        topic: ^topic,
        payload: %{media_asset: ^updated_media_asset, job_posting: ^job_posting}
      }
    end

    test "broadcasts to job_application_messages topic when updating message media asset", %{
      message: message
    } do
      message = Repo.preload(message, [:media_asset])
      media_asset = media_asset_fixture(message, %{})
      topic = "job_application_messages:#{message.job_application_id}:media_assets"

      Endpoint.subscribe(topic)

      {:ok, updated_media_asset} = Media.update_media_asset(media_asset, %{status: :failed})

      assert_receive %Broadcast{
        event: "media_asset_updated",
        topic: ^topic,
        payload: %{media_asset: ^updated_media_asset, message: broadcasted_message}
      }

      assert broadcasted_message.id == message.id
      assert broadcasted_message.media_asset.id == updated_media_asset.id
      assert broadcasted_message.media_asset.status == :failed
    end
  end

  describe "delete_media_asset/1" do
    setup [:create_test_data]

    test "deletes the media asset", %{job_posting: job_posting, scope: scope} do
      media_asset = media_asset_fixture(job_posting, %{})
      assert {:ok, %MediaAsset{}} = Media.delete_media_asset(media_asset)
      refute Media.get_media_asset(scope, media_asset.id)
    end

    test "returns error when media asset does not exist" do
      non_existent_id = Ecto.UUID.generate()
      media_asset = %MediaAsset{id: non_existent_id}

      assert_raise Ecto.StaleEntryError, fn ->
        Media.delete_media_asset(media_asset)
      end
    end
  end

  describe "change_media_asset/1" do
    setup [:create_test_data]

    test "returns a media asset changeset", %{message: message} do
      media_asset = media_asset_fixture(message, %{})
      assert %Ecto.Changeset{} = Media.change_media_asset(media_asset)
    end

    test "returns a changeset even with nil values", %{message: message} do
      media_asset = media_asset_fixture(message, %{})
      changeset = Media.change_media_asset(media_asset, %{file_name: nil})
      assert %Ecto.Changeset{} = changeset
      assert changeset.valid?
    end
  end

  describe "get_media_asset_url/1" do
    test "returns nil when media_asset is nil" do
      refute Media.get_media_asset_url(nil)
    end

    test "returns nil when media_asset has nil upload_id" do
      media_asset = %MediaAsset{upload_id: nil}
      refute Media.get_media_asset_url(media_asset)
    end

    test "returns URL string when media_asset has valid upload_id" do
      upload_id = Ecto.UUID.generate()
      media_asset = %MediaAsset{upload_id: upload_id}

      result = Media.get_media_asset_url(media_asset)

      # Should return a string URL (TigrisHelper.get_presigned_download_url result)
      assert is_binary(result)
      # The URL should contain the upload_id
      assert String.contains?(result, upload_id)
    end

    test "handles edge case with empty string upload_id" do
      media_asset = %MediaAsset{upload_id: ""}
      result = Media.get_media_asset_url(media_asset)

      # Should still call TigrisHelper.get_presigned_download_url with empty string
      # The function doesn't explicitly handle empty string, so it passes through
      assert is_binary(result)
    end

    test "handles various valid upload_id formats" do
      # Test with UUID format
      uuid_upload_id = Ecto.UUID.generate()
      uuid_media_asset = %MediaAsset{upload_id: uuid_upload_id}
      uuid_result = Media.get_media_asset_url(uuid_media_asset)

      assert is_binary(uuid_result)
      assert String.contains?(uuid_result, uuid_upload_id)

      # Test with custom string format
      custom_upload_id = "custom-upload-123"
      custom_media_asset = %MediaAsset{upload_id: custom_upload_id}
      custom_result = Media.get_media_asset_url(custom_media_asset)

      assert is_binary(custom_result)
      assert String.contains?(custom_result, custom_upload_id)
    end

    test "function signature matches expected pattern matching" do
      # Test the actual pattern matching behavior described in the bug fix

      # Pattern 1: nil input
      refute Media.get_media_asset_url(nil)

      # Pattern 2: MediaAsset with nil upload_id
      nil_upload_asset = %MediaAsset{
        id: Ecto.UUID.generate(),
        upload_id: nil,
        file_name: "test.jpg",
        status: :uploaded,
        type: "image/jpeg"
      }

      refute Media.get_media_asset_url(nil_upload_asset)

      # Pattern 3: MediaAsset with valid upload_id
      valid_upload_asset = %MediaAsset{
        id: Ecto.UUID.generate(),
        upload_id: "valid-upload-id",
        file_name: "test.jpg",
        status: :uploaded,
        type: "image/jpeg"
      }

      result = Media.get_media_asset_url(valid_upload_asset)
      assert is_binary(result)
      assert String.contains?(result, "valid-upload-id")
    end
  end

  describe "parent association" do
    setup [:create_test_data]

    test "different parent types result in proper associations", %{
      job_application: job_application,
      job_posting: job_posting,
      message: message
    } do
      app_media = media_asset_fixture(job_application, %{})
      posting_media = media_asset_fixture(job_posting, %{})
      message_media = media_asset_fixture(message, %{})

      assert app_media.job_application_id == job_application.id
      refute app_media.job_posting_id
      refute app_media.message_id

      assert posting_media.job_posting_id == job_posting.id
      refute posting_media.job_application_id
      refute posting_media.message_id

      assert message_media.message_id == message.id
      refute message_media.job_application_id
      refute message_media.job_posting_id
    end
  end
end
