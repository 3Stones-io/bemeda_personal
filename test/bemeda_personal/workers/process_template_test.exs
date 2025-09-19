defmodule BemedaPersonal.Workers.ProcessTemplateTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.CompanyTemplatesFixtures
  import BemedaPersonal.MediaFixtures
  import ExUnit.CaptureLog
  import Mox

  alias BemedaPersonal.CompanyTemplates
  alias BemedaPersonal.CompanyTemplates.CompanyTemplate
  alias BemedaPersonal.Documents.MockProcessor
  alias BemedaPersonal.Documents.MockStorage
  alias BemedaPersonal.Repo
  alias BemedaPersonal.Workers.ProcessTemplate

  setup :verify_on_exit!

  describe "perform/1" do
    test "successfully processes template with variables" do
      %{template: template, upload_id: upload_id} = setup_template_with_media_asset()

      expect(MockStorage, :download_file, fn ^upload_id ->
        {:ok, "mock docx content"}
      end)

      expect(MockProcessor, :extract_variables, fn _content ->
        ["FirstName", "LastName", "Position"]
      end)

      job = %Oban.Job{args: %{"template_id" => template.id}}

      assert :ok = ProcessTemplate.perform(job)

      updated_template = Repo.get!(CompanyTemplate, template.id)
      assert updated_template.status == :active
      assert updated_template.variables == ["FirstName", "LastName", "Position"]
    end

    test "handles template not found" do
      job = %Oban.Job{args: %{"template_id" => Ecto.UUID.generate()}}

      assert capture_log(fn ->
               assert {:error, :not_found} = ProcessTemplate.perform(job)
             end) =~ "Template not found"
    end

    test "handles processing error and updates template status" do
      %{template: template, upload_id: upload_id} = setup_template_with_media_asset()

      expect(MockStorage, :download_file, fn ^upload_id ->
        {:error, "Storage error"}
      end)

      job = %Oban.Job{args: %{"template_id" => template.id}}

      assert {:error, "Storage error"} = ProcessTemplate.perform(job)

      updated_template = Repo.get!(CompanyTemplate, template.id)
      assert updated_template.status == :failed
      assert String.contains?(updated_template.error_message, "Storage error")
    end

    test "handles template without media asset" do
      %{template: template} =
        setup_template_with_media_asset(
          template_attrs: %{media_asset_id: nil, status: :processing},
          skip_media_asset_creation: true
        )

      job = %Oban.Job{args: %{"template_id" => template.id}}

      assert {:error, "No media asset found"} = ProcessTemplate.perform(job)

      updated_template = Repo.get!(CompanyTemplate, template.id)
      assert updated_template.status == :failed
    end

    test "handles media asset without upload_id" do
      %{template: template} =
        setup_template_with_media_asset(media_asset_attrs: %{upload_id: nil})

      job = %Oban.Job{args: %{"template_id" => template.id}}

      assert {:error, "No upload_id found in media asset"} = ProcessTemplate.perform(job)

      updated_template = Repo.get!(CompanyTemplate, template.id)
      assert updated_template.status == :failed
    end

    test "processes template with multiple variables" do
      %{template: template, upload_id: upload_id} = setup_template_with_media_asset()

      expect(MockStorage, :download_file, fn ^upload_id ->
        {:ok, "mock docx content"}
      end)

      expect(MockProcessor, :extract_variables, fn _content ->
        ["FirstName", "LastName", "Position_Title"]
      end)

      job = %Oban.Job{args: %{"template_id" => template.id}}

      assert :ok = ProcessTemplate.perform(job)

      updated_template = Repo.get!(CompanyTemplate, template.id)
      assert updated_template.variables == ["FirstName", "LastName", "Position_Title"]
    end

    test "handles processor error during variable extraction" do
      %{template: template, upload_id: upload_id} = setup_template_with_media_asset()

      expect(MockStorage, :download_file, fn ^upload_id ->
        {:ok, "mock docx content"}
      end)

      expect(MockProcessor, :extract_variables, fn _content ->
        raise "Processing failed"
      end)

      job = %Oban.Job{args: %{"template_id" => template.id}}

      assert_raise RuntimeError, "Processing failed", fn ->
        ProcessTemplate.perform(job)
      end
    end

    test "handles empty variables list" do
      %{template: template, upload_id: upload_id} = setup_template_with_media_asset()

      expect(MockStorage, :download_file, fn ^upload_id ->
        {:ok, "mock docx content"}
      end)

      expect(MockProcessor, :extract_variables, fn _content ->
        []
      end)

      job = %Oban.Job{args: %{"template_id" => template.id}}

      assert :ok = ProcessTemplate.perform(job)

      updated_template = Repo.get!(CompanyTemplate, template.id)
      assert updated_template.status == :active
      assert updated_template.variables == []
    end

    test "handles error during template update" do
      %{template: template} = setup_template_with_media_asset()

      job = %Oban.Job{args: %{"template_id" => template.id}}

      Repo.delete!(template)

      assert capture_log(fn ->
               assert {:error, :not_found} = ProcessTemplate.perform(job)
             end) =~ "Template not found"
    end

    test "handles different error formats in format_error" do
      %{template: template, upload_id: upload_id} = setup_template_with_media_asset()

      expect(MockStorage, :download_file, fn ^upload_id ->
        {:error, {:timeout, "Connection timeout"}}
      end)

      job = %Oban.Job{args: %{"template_id" => template.id}}

      assert {:error, {:timeout, "Connection timeout"}} = ProcessTemplate.perform(job)

      updated_template = Repo.get!(CompanyTemplate, template.id)
      assert updated_template.status == :failed

      assert String.contains?(
               updated_template.error_message,
               "{:timeout, \"Connection timeout\"}"
             )
    end

    test "handles atom error format" do
      %{template: template, upload_id: upload_id} = setup_template_with_media_asset()

      expect(MockStorage, :download_file, fn ^upload_id ->
        {:error, :network_error}
      end)

      job = %Oban.Job{args: %{"template_id" => template.id}}

      assert {:error, :network_error} = ProcessTemplate.perform(job)

      updated_template = Repo.get!(CompanyTemplate, template.id)
      assert updated_template.status == :failed
      assert String.contains?(updated_template.error_message, ":network_error")
    end

    test "handles non-tuple error format" do
      %{template: template, upload_id: upload_id} = setup_template_with_media_asset()

      expect(MockStorage, :download_file, fn ^upload_id ->
        {:error, :file_not_found}
      end)

      job = %Oban.Job{args: %{"template_id" => template.id}}

      assert {:error, :file_not_found} = ProcessTemplate.perform(job)

      updated_template = Repo.get!(CompanyTemplate, template.id)
      assert updated_template.status == :failed

      assert String.contains?(
               updated_template.error_message,
               "Failed to process template: :file_not_found"
             )
    end

    test "handles broadcast error gracefully" do
      %{template: template, upload_id: upload_id} = setup_template_with_media_asset()

      expect(MockStorage, :download_file, fn ^upload_id ->
        {:ok, "mock docx content"}
      end)

      expect(MockProcessor, :extract_variables, fn _content ->
        ["FirstName"]
      end)

      job = %Oban.Job{args: %{"template_id" => template.id}}

      assert :ok = ProcessTemplate.perform(job)

      updated_template = Repo.get!(CompanyTemplate, template.id)
      assert updated_template.status == :active
      assert updated_template.variables == ["FirstName"]
    end
  end

  defp setup_template_with_media_asset(opts \\ []) do
    user = employer_user_fixture()
    company = company_fixture(user)

    template_attrs = Keyword.get(opts, :template_attrs, %{status: :processing})
    template = template_fixture(company, template_attrs)

    if Keyword.get(opts, :skip_media_asset_creation, false) do
      %{
        user: user,
        company: company,
        template: template,
        upload_id: nil,
        media_asset: nil
      }
    else
      upload_id = Ecto.UUID.generate()
      media_asset_attrs = Keyword.get(opts, :media_asset_attrs, %{upload_id: upload_id})
      media_asset = media_asset_fixture(template, media_asset_attrs)

      final_template =
        if Keyword.get(opts, :skip_media_asset_update, false) do
          template
        else
          {:ok, updated_template} =
            CompanyTemplates.update_template(template, %{
              media_asset_id: media_asset.id
            })

          updated_template
        end

      %{
        user: user,
        company: company,
        template: final_template,
        upload_id: upload_id,
        media_asset: media_asset
      }
    end
  end
end
