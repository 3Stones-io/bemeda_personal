defmodule BemedaPersonal.MediaTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.ChatFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures
  import BemedaPersonal.MediaFixtures

  alias BemedaPersonal.Media
  alias BemedaPersonal.Media.MediaAsset
  alias BemedaPersonalWeb.Endpoint
  alias Phoenix.Socket.Broadcast

  defp create_test_data(_context) do
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

  describe "list_media_assets/0" do
    setup [:create_test_data]

    test "returns all media assets", %{
      job_application: job_application,
      job_posting: job_posting,
      message: message
    } do
      media_asset1 = media_asset_fixture(job_application, %{})
      media_asset2 = media_asset_fixture(job_posting, %{})
      media_asset3 = media_asset_fixture(message, %{})

      assert media_assets = Media.list_media_assets()
      assert Enum.find(media_assets, &(&1.id == media_asset1.id))
      assert Enum.find(media_assets, &(&1.id == media_asset2.id))
      assert Enum.find(media_assets, &(&1.id == media_asset3.id))
    end
  end

  describe "get_media_asset!/1" do
    setup [:create_test_data]

    test "returns the media asset with given id", %{job_application: job_application} do
      media_asset = media_asset_fixture(job_application, %{})
      fetched_asset = Media.get_media_asset!(media_asset.id)
      assert fetched_asset.id == media_asset.id
      assert fetched_asset.file_name == media_asset.file_name
    end

    test "raises error when media asset with id does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Media.get_media_asset!(Ecto.UUID.generate())
      end
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

    test "allows updating fields with nil values", %{job_application: job_application} do
      media_asset = media_asset_fixture(job_application, %{})
      invalid_attrs = %{file_name: nil, type: nil}

      {:ok, updated_media_asset} = Media.update_media_asset(media_asset, invalid_attrs)
      assert updated_media_asset.file_name == nil
      fetched_media_asset = Media.get_media_asset!(media_asset.id)
      assert fetched_media_asset.id == updated_media_asset.id
      assert fetched_media_asset.file_name == nil
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

    test "deletes the media asset", %{job_posting: job_posting} do
      media_asset = media_asset_fixture(job_posting, %{})
      assert {:ok, %MediaAsset{}} = Media.delete_media_asset(media_asset)
      assert_raise Ecto.NoResultsError, fn -> Media.get_media_asset!(media_asset.id) end
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
