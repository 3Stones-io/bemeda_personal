defmodule BemedaPersonal.Workers.GenerateContractTest do
  use BemedaPersonal.DataCase, async: true
  use Oban.Testing, repo: BemedaPersonal.Repo

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobOffersFixtures
  import BemedaPersonal.JobPostingsFixtures
  import ExUnit.CaptureLog
  import Mox

  alias BemedaPersonal.CompanyTemplates
  alias BemedaPersonal.CompanyTemplates.CompanyTemplate
  alias BemedaPersonal.Documents.MockProcessor
  alias BemedaPersonal.Documents.MockStorage
  alias BemedaPersonal.JobOffers
  alias BemedaPersonal.JobOffers.GenerateContract
  alias BemedaPersonal.Media
  alias BemedaPersonal.Repo
  alias BemedaPersonalWeb.Endpoint

  setup :verify_on_exit!

  setup do
    temp_dir = System.tmp_dir!()
    processed_path = Path.join(temp_dir, "processed_#{System.unique_integer()}.docx")
    pdf_path = Path.join(temp_dir, "output_#{System.unique_integer()}.pdf")

    File.write!(processed_path, "mock processed document content")
    File.write!(pdf_path, "mock pdf content")

    original_template_id = Application.get_env(:bemeda_personal, :default_offer_template_id)

    on_exit(fn ->
      File.rm_rf(processed_path)
      File.rm_rf(pdf_path)

      if original_template_id do
        Application.put_env(:bemeda_personal, :default_offer_template_id, original_template_id)
      else
        Application.delete_env(:bemeda_personal, :default_offer_template_id)
      end
    end)

    %{
      processed_path: processed_path,
      pdf_path: pdf_path
    }
  end

  describe "perform/1" do
    test "successfully generates PDF using company template and updates job offer status", %{
      processed_path: processed_path,
      pdf_path: pdf_path
    } do
      user = user_fixture()
      company = company_fixture(user_fixture())
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      job_offer =
        job_offer_fixture(%{
          job_application_id: job_application.id,
          status: :pending,
          variables: %{
            "First_Name" => "John",
            "Last_Name" => "Doe",
            "Job_Title" => "Engineer"
          }
        })

      template_upload_id = Ecto.UUID.generate()

      {:ok, company_template} =
        CompanyTemplates.create_template(company, %{
          name: "company_template.docx",
          status: :active
        })

      {:ok, _media_asset} =
        Media.create_media_asset(company_template, %{
          file_name: "company_template.docx",
          status: :uploaded,
          type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
          upload_id: template_upload_id
        })

      expect(MockStorage, :download_file, fn ^template_upload_id ->
        {:ok, "mock company template content"}
      end)

      expect(MockStorage, :upload_file, fn _pdf_upload_id, _pdf_content, "application/pdf" ->
        :ok
      end)

      expect(MockProcessor, :replace_variables, fn _doc_path, _variables -> processed_path end)
      expect(MockProcessor, :convert_to_pdf, fn ^processed_path -> pdf_path end)

      company_topic = "job_application:company:#{company.id}"
      Endpoint.subscribe(company_topic)

      user_topic = "job_application:user:#{user.id}"
      Endpoint.subscribe(user_topic)

      assert :ok = perform_job(GenerateContract, %{job_offer_id: job_offer.id})

      updated_offer = JobOffers.get_job_offer_by_application(job_application.id)
      assert updated_offer.status == :extended
      assert updated_offer.message
      assert updated_offer.message.media_asset

      assert_received %Phoenix.Socket.Broadcast{
        topic: ^company_topic,
        event: "job_offer_updated",
        payload: %{job_offer: company_broadcast_job_offer}
      }

      assert company_broadcast_job_offer.id == updated_offer.id
      assert company_broadcast_job_offer.status == :extended

      assert_received %Phoenix.Socket.Broadcast{
        topic: ^user_topic,
        event: "job_offer_updated",
        payload: %{job_offer: user_broadcast_job_offer}
      }

      assert user_broadcast_job_offer.id == updated_offer.id
      assert user_broadcast_job_offer.status == :extended
    end

    test "handles PDF generation failure gracefully" do
      user = user_fixture()
      company = company_fixture(user_fixture())
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      job_offer =
        job_offer_fixture(%{
          job_application_id: job_application.id,
          status: :pending
        })

      template_upload_id = Ecto.UUID.generate()

      expect(MockStorage, :download_file, fn ^template_upload_id ->
        {:error, "Download failed"}
      end)

      Application.put_env(:bemeda_personal, :default_offer_template_id, template_upload_id)

      assert capture_log(fn ->
               assert {:error, _reason} =
                        perform_job(GenerateContract, %{job_offer_id: job_offer.id})
             end)

      updated_offer = JobOffers.get_job_offer_by_application(job_application.id)
      assert updated_offer.status == :pending
      refute updated_offer.message
    end

    test "uses default template when no company template exists", %{
      processed_path: processed_path,
      pdf_path: pdf_path
    } do
      job_offer = create_test_job_offer()

      company_id = job_offer.job_application.job_posting.company_id
      refute CompanyTemplates.get_active_template(company_id)

      Application.delete_env(:bemeda_personal, :default_offer_template_id)

      setup_successful_pdf_mocks(processed_path, pdf_path, 2)

      assert :ok = perform_job(GenerateContract, %{job_offer_id: job_offer.id})

      default_template_id = Application.get_env(:bemeda_personal, :default_offer_template_id)
      assert default_template_id
      assert is_binary(default_template_id)
    end

    test "uses active template and ignores processing template", %{
      processed_path: processed_path,
      pdf_path: pdf_path
    } do
      user = user_fixture()
      company = company_fixture(user_fixture())
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      job_offer =
        job_offer_fixture(%{
          job_application_id: job_application.id,
          status: :pending
        })

      active_template_upload_id = Ecto.UUID.generate()

      {:ok, active_template} =
        CompanyTemplates.create_template(company, %{
          name: "active_template.docx",
          status: :active
        })

      {:ok, _media_asset} =
        Media.create_media_asset(active_template, %{
          file_name: "active_template.docx",
          status: :uploaded,
          type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
          upload_id: active_template_upload_id
        })

      processing_template_upload_id = Ecto.UUID.generate()

      {:ok, processing_template} =
        CompanyTemplates.create_template(company, %{
          name: "processing_template.docx",
          status: :processing
        })

      {:ok, _media_asset} =
        Media.create_media_asset(processing_template, %{
          file_name: "processing_template.docx",
          status: :uploaded,
          type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
          upload_id: processing_template_upload_id
        })

      assert %CompanyTemplate{} =
               active_template = CompanyTemplates.get_active_template(company.id)

      assert active_template.status == :active
      assert active_template.media_asset
      assert active_template.media_asset.upload_id == active_template_upload_id

      expect(MockStorage, :download_file, fn ^active_template_upload_id ->
        {:ok, "mock active template content"}
      end)

      expect(MockStorage, :upload_file, fn _pdf_upload_id, _pdf_content, "application/pdf" ->
        :ok
      end)

      expect(MockProcessor, :replace_variables, fn _doc_path, _variables -> processed_path end)
      expect(MockProcessor, :convert_to_pdf, fn ^processed_path -> pdf_path end)

      assert :ok = perform_job(GenerateContract, %{job_offer_id: job_offer.id})

      updated_offer = JobOffers.get_job_offer_by_application(job_application.id)
      assert updated_offer.status == :extended
    end

    test "creates placeholder template when default template file not found", %{
      processed_path: processed_path,
      pdf_path: pdf_path
    } do
      job_offer = create_test_job_offer()

      Application.delete_env(:bemeda_personal, :default_offer_template_id)

      setup_successful_pdf_mocks(processed_path, pdf_path, 2)

      assert :ok = perform_job(GenerateContract, %{job_offer_id: job_offer.id})

      assert Application.get_env(:bemeda_personal, :default_offer_template_id)
    end

    test "handles missing job offer gracefully" do
      non_existent_id = Ecto.UUID.generate()

      assert_raise Ecto.NoResultsError, fn ->
        perform_job(GenerateContract, %{job_offer_id: non_existent_id})
      end
    end
  end

  defp create_test_job_offer(attrs \\ %{}) do
    user = user_fixture()
    company = company_fixture(user_fixture())
    job_posting = job_posting_fixture(company)
    job_application = job_application_fixture(user, job_posting)

    default_attrs = %{
      job_application_id: job_application.id,
      status: :pending
    }

    job_offer = job_offer_fixture(Map.merge(default_attrs, attrs))

    Repo.preload(job_offer,
      job_application: [:user, job_posting: [company: :admin_user]]
    )
  end

  defp setup_successful_pdf_mocks(processed_path, pdf_path, upload_count) do
    expect(MockStorage, :upload_file, upload_count, fn _upload_id, _content, _type -> :ok end)

    expect(MockStorage, :download_file, fn _template_upload_id ->
      {:ok, "mock template content"}
    end)

    expect(MockProcessor, :replace_variables, fn _doc_path, _variables -> processed_path end)
    expect(MockProcessor, :convert_to_pdf, fn ^processed_path -> pdf_path end)
  end
end
