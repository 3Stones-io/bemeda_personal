defmodule BemedaPersonal.DocumentsTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import Mox

  alias BemedaPersonal.Chat
  alias BemedaPersonal.Documents
  alias BemedaPersonal.Documents.MockProcessor
  alias BemedaPersonal.Documents.MockStorage
  alias BemedaPersonal.Media

  setup :verify_on_exit!

  setup do
    user = user_fixture()
    company = company_fixture(user_fixture(%{email: "company@example.com"}))
    job = job_posting_fixture(company)
    job_application = job_application_fixture(user, job)

    template_path = "test/support/fixtures/files/Копия \"Freelance Contract\".docx"
    upload_id = Ecto.UUID.generate()

    {:ok, message} =
      Chat.create_message_with_media(user, job_application, %{
        "media_data" => %{
          "file_name" => "template.docx",
          "status" => :uploaded,
          "type" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
          "upload_id" => upload_id
        }
      })

    temp_dir = System.tmp_dir!()
    processed_path = Path.join(temp_dir, "processed.docx")
    pdf_path = Path.join(temp_dir, "processed.pdf")

    File.write!(processed_path, "mock document content")
    File.write!(pdf_path, "mock pdf content")

    on_exit(fn ->
      File.rm_rf(processed_path)
      File.rm_rf(pdf_path)
    end)

    %{
      job_application: job_application,
      message: message,
      pdf_path: pdf_path,
      processed_path: processed_path,
      template_path: template_path,
      upload_id: upload_id,
      user: user
    }
  end

  describe "extract_template_variables/1" do
    test "extracts variables from a document", %{
      message: message,
      template_path: template_path,
      upload_id: upload_id
    } do
      expect(MockStorage, :download_file, fn ^upload_id ->
        {:ok, File.read!(template_path)}
      end)

      expect(MockProcessor, :extract_variables, fn _path ->
        [
          "Sender.FirstName",
          "Sender.LastName",
          "Sender.Company"
        ]
      end)

      {:ok, variables} = Documents.extract_template_variables(message.id)

      assert is_list(variables)
      assert "Sender.FirstName" in variables
      assert "Sender.LastName" in variables
      assert "Sender.Company" in variables
      refute "Client.FirstName" in variables
    end

    test "handles no media asset case", %{message: message} do
      message.id
      |> Media.get_media_asset_by_message_id()
      |> Media.delete_media_asset()

      assert_raise WithClauseError, fn ->
        Documents.extract_template_variables(message.id)
      end
    end

    test "handles empty upload_id case", %{message: message} do
      message.id
      |> Media.get_media_asset_by_message_id()
      |> Media.update_media_asset(%{upload_id: nil})

      expect(MockStorage, :download_file, fn nil ->
        {:error, "Invalid upload_id"}
      end)

      assert {:error, reason} =
               Documents.extract_template_variables(message.id)

      assert reason =~ "Failed to download document"
    end

    test "handles document download error", %{message: message, upload_id: upload_id} do
      expect(MockStorage, :download_file, fn ^upload_id ->
        {:error, "Download failed"}
      end)

      assert {:error, reason} =
               Documents.extract_template_variables(message.id)

      assert reason =~ "Failed to download document"
    end

    test "handles invalid document format", %{message: message, upload_id: upload_id} do
      expect(MockStorage, :download_file, fn ^upload_id ->
        {:ok, "<?xml version=\"1.0\" encoding=\"UTF-8\"?><root>Invalid document</root>"}
      end)

      assert {:error, "Invalid document format"} =
               Documents.extract_template_variables(message.id)
    end
  end

  describe "generate_pdf/4" do
    test "successfully generates PDF from template", %{
      job_application: job_application,
      message: message,
      pdf_path: pdf_path,
      processed_path: processed_path,
      upload_id: upload_id,
      user: user
    } do
      variables = %{
        "Sender.Company" => "ACME Corp",
        "Sender.FirstName" => "John",
        "Sender.LastName" => "Doe"
      }

      stub(MockStorage, :download_file, fn ^upload_id ->
        {:ok, "mock document content"}
      end)

      expect(MockProcessor, :replace_variables, fn _doc_path, ^variables ->
        processed_path
      end)

      expect(MockProcessor, :convert_to_pdf, fn ^processed_path ->
        pdf_path
      end)

      expect(MockStorage, :upload_file, fn _pdf_id, _content, "application/pdf" ->
        :ok
      end)

      {:ok, pdf_message} =
        Documents.generate_pdf(message.id, variables, user, job_application)

      assert %Chat.Message{} = pdf_message
      assert pdf_message.media_asset.file_name =~ ".pdf"
      assert pdf_message.media_asset.type == "application/pdf"
      assert pdf_message.media_asset.status == :uploaded
    end

    test "handles media asset not found error", %{
      job_application: job_application,
      message: message,
      user: user
    } do
      variables = %{"test" => "value"}

      message.id
      |> Media.get_media_asset_by_message_id()
      |> Media.delete_media_asset()

      assert {:error, "Message or media asset not found"} =
               Documents.generate_pdf(message.id, variables, user, job_application)
    end

    test "handles document download error", %{
      job_application: job_application,
      message: message,
      upload_id: upload_id,
      user: user
    } do
      variables = %{"test" => "value"}

      expect(MockStorage, :download_file, fn ^upload_id ->
        {:error, "Download failed"}
      end)

      assert {:error, reason} =
               Documents.generate_pdf(message.id, variables, user, job_application)

      assert reason =~ "Failed to download document"
    end

    test "handles invalid document format", %{
      job_application: job_application,
      message: message,
      upload_id: upload_id,
      user: user
    } do
      variables = %{"test" => "value"}

      expect(MockStorage, :download_file, fn ^upload_id ->
        {:ok, "<?xml version=\"1.0\" encoding=\"UTF-8\"?><root>Invalid document</root>"}
      end)

      assert {:error, "Invalid document format"} =
               Documents.generate_pdf(message.id, variables, user, job_application)
    end

    test "handles PDF upload error", %{
      job_application: job_application,
      message: message,
      pdf_path: pdf_path,
      processed_path: processed_path,
      upload_id: upload_id,
      user: user
    } do
      variables = %{
        "Sender.FirstName" => "John",
        "Sender.LastName" => "Doe",
        "Sender.Company" => "ACME Corp"
      }

      stub(MockStorage, :download_file, fn ^upload_id ->
        {:ok, "mock document content"}
      end)

      expect(MockProcessor, :replace_variables, fn _doc_path, ^variables ->
        processed_path
      end)

      expect(MockProcessor, :convert_to_pdf, fn ^processed_path ->
        pdf_path
      end)

      expect(MockStorage, :upload_file, fn _pdf_id, _content, "application/pdf" ->
        {:error, "Upload failed"}
      end)

      assert {:error, reason} =
               Documents.generate_pdf(message.id, variables, user, job_application)

      assert reason =~ "Failed to upload PDF"
    end
  end
end
