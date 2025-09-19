defmodule BemedaPersonal.JobOffers.GenerateContract do
  @moduledoc """
  Background job for generating PDF contracts from job offers.

  This job handles the complete contract generation workflow:
  1. Uploads default template to storage if needed
  2. Generates PDF directly from template using Documents infrastructure
  3. Creates message with generated PDF
  4. Updates job offer with generated PDF reference
  """

  use Oban.Worker, max_attempts: 3

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Chat
  alias BemedaPersonal.CompanyTemplates
  alias BemedaPersonal.Documents
  alias BemedaPersonal.JobOffers
  alias BemedaPersonal.JobOffers.JobOffer
  alias BemedaPersonal.Repo
  alias BemedaPersonalWeb.Endpoint

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"job_offer_id" => job_offer_id}}) do
    with {:ok, job_offer} <- load_job_offer(job_offer_id),
         :ok <- check_contract_not_exists(job_offer),
         {:ok, pdf_id} <- generate_contract_pdf(job_offer),
         {:ok, updated_offer} <- finalize_job_offer(job_offer, pdf_id) do
      broadcast_job_offer_updates(updated_offer)
      :ok
    else
      {:error, :contract_already_exists} ->
        Logger.info("Contract already exists for job offer #{job_offer_id}")
        :ok

      {:error, reason} ->
        Logger.error(
          "Contract generation failed for job offer #{job_offer_id}: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  defp load_job_offer(job_offer_id) do
    # For background jobs, we don't have user context, so we need to load without scope first
    # to get the company admin user to create scope for subsequent operations
    job_offer =
      JobOffer
      |> Repo.get!(job_offer_id)
      |> Repo.preload([:message, job_application: [:user, job_posting: [company: :admin_user]]])

    {:ok, job_offer}
  end

  defp scope_for_job_offer(job_offer) do
    admin_user = job_offer.job_application.job_posting.company.admin_user
    company = job_offer.job_application.job_posting.company

    admin_user
    |> Scope.for_user()
    |> Scope.put_company(company)
  end

  defp check_contract_not_exists(%{message_id: message_id}) when is_binary(message_id),
    do: {:error, :contract_already_exists}

  defp check_contract_not_exists(_job_offer), do: :ok

  defp generate_contract_pdf(job_offer) do
    company_id = job_offer.job_application.job_posting.company_id
    template_upload_id = get_template_upload_id(company_id)

    with {:ok, doc_path} <- download_template(template_upload_id),
         doc_path <- Documents.Processor.replace_variables(doc_path, job_offer.variables),
         pdf_path <- Documents.Processor.convert_to_pdf(doc_path) do
      upload_pdf(pdf_path)
    end
  end

  defp finalize_job_offer(job_offer, pdf_id) do
    with {:ok, pdf_message} <- create_pdf_message(pdf_id, job_offer),
         scope <- scope_for_job_offer(job_offer),
         {:ok, updated_offer} <-
           JobOffers.update_job_offer(scope, job_offer, pdf_message, %{
             status: :extended,
             contract_generated_at: DateTime.utc_now()
           }) do
      updated_offer = Repo.preload(updated_offer, message: :media_asset)
      {:ok, updated_offer}
    end
  end

  defp broadcast_job_offer_updates(job_offer) do
    company_id = job_offer.job_application.job_posting.company_id
    user_id = job_offer.job_application.user_id

    Endpoint.broadcast(
      "job_application:company:#{company_id}",
      "job_offer_updated",
      %{job_offer: job_offer}
    )

    Endpoint.broadcast(
      "job_application:user:#{user_id}",
      "job_offer_updated",
      %{job_offer: job_offer}
    )
  end

  defp get_template_upload_id(company_id) do
    case CompanyTemplates.get_active_template(company_id) do
      %{media_asset: %{upload_id: upload_id}} when is_binary(upload_id) ->
        upload_id

      _template ->
        get_or_upload_default_template()
    end
  end

  defp get_or_upload_default_template do
    case Application.get_env(:bemeda_personal, :default_offer_template_id) do
      nil -> upload_default_template()
      upload_id -> upload_id
    end
  end

  defp upload_default_template do
    template_path = build_template_path()
    upload_id = Ecto.UUID.generate()

    with {:ok, content} <- File.read(template_path),
         :ok <- upload_template_content(upload_id, content) do
      Application.put_env(:bemeda_personal, :default_offer_template_id, upload_id)
      upload_id
    else
      {:error, reason} ->
        raise "Failed to upload default template: #{inspect(reason)}"
    end
  end

  defp build_template_path do
    Path.join([
      :code.priv_dir(:bemeda_personal),
      "documents",
      "job_offers",
      "default_template.docx"
    ])
  end

  defp upload_template_content(upload_id, content) do
    Documents.Storage.upload_file(
      upload_id,
      content,
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    )
  end

  defp download_template(upload_id) do
    temp_dir = System.tmp_dir!()
    local_path = Path.join(temp_dir, "template_#{upload_id}.docx")

    with :ok <- ensure_temp_directory(local_path),
         {:ok, content} <- fetch_template_content(upload_id),
         :ok <- File.write(local_path, content) do
      {:ok, local_path}
    end
  end

  defp ensure_temp_directory(file_path) do
    dir_path = Path.dirname(file_path)

    case File.mkdir_p(dir_path) do
      :ok -> :ok
      {:error, reason} -> {:error, "Failed to create temp directory: #{inspect(reason)}"}
    end
  end

  defp fetch_template_content(upload_id) do
    case Documents.Storage.download_file(upload_id) do
      {:ok, "<?xml" <> _rest} ->
        {:error, "Invalid document format"}

      {:ok, content} ->
        {:ok, content}

      {:error, reason} ->
        {:error, "Failed to download document: #{inspect(reason)}"}
    end
  end

  defp upload_pdf(pdf_path) do
    pdf_id = Ecto.UUID.generate()

    with {:ok, content} <- File.read(pdf_path),
         :ok <- Documents.Storage.upload_file(pdf_id, content, "application/pdf") do
      {:ok, pdf_id}
    else
      {:error, reason} ->
        {:error, "Failed to upload PDF: #{inspect(reason)}"}
    end
  end

  defp create_pdf_message(pdf_id, job_offer) do
    admin_user = job_offer.job_application.job_posting.company.admin_user
    company = job_offer.job_application.job_posting.company

    scope =
      admin_user
      |> Scope.for_user()
      |> Scope.put_company(company)

    Chat.create_message_with_media(
      scope,
      admin_user,
      job_offer.job_application,
      %{
        "content" => "Generated contract",
        "media_data" => %{
          "file_name" => "job_offer_contract.pdf",
          "type" => "application/pdf",
          "status" => :uploaded,
          "upload_id" => pdf_id
        }
      }
    )
  end
end
