defmodule BemedaPersonal.Workers.ProcessTemplate do
  @moduledoc """
  Background worker for processing uploaded DOCX templates.

  Extracts variables from the template and activates it upon successful processing.
  """

  use Oban.Worker, queue: :default, max_attempts: 3

  alias BemedaPersonal.CompanyTemplates
  alias BemedaPersonal.CompanyTemplates.CompanyTemplate
  alias BemedaPersonal.Documents.Processor
  alias BemedaPersonal.Documents.Storage
  alias BemedaPersonalWeb.Endpoint

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"template_id" => template_id}}) do
    with {:ok, template} <- fetch_template(template_id),
         {:ok, variables} <- process_template(template),
         {:ok, updated_template} <- update_template_success(template, variables),
         :ok <- broadcast_update(template.company_id, updated_template) do
      :ok
    else
      {:error, :not_found} = error ->
        Logger.error("Template not found: #{template_id}")
        error

      {:error, reason} ->
        handle_processing_error(template_id, reason)
    end
  end

  defp fetch_template(template_id) do
    case CompanyTemplates.get_template(template_id) do
      %CompanyTemplate{} = template ->
        {:ok, template}

      nil ->
        {:error, :not_found}
    end
  end

  defp process_template(template) do
    with {:ok, upload_id} <- get_upload_id(template),
         {:ok, content} <- Storage.download_file(upload_id),
         {:ok, temp_file_path} <- save_to_temp_file(content, template.name) do
      variables = Processor.extract_variables(temp_file_path)

      File.rm(temp_file_path)

      {:ok, variables}
    end
  end

  defp save_to_temp_file(content, original_filename) do
    temp_dir = System.tmp_dir!()
    timestamp = System.system_time(:millisecond)
    temp_filename = "template_#{timestamp}_#{original_filename}"
    temp_file_path = Path.join(temp_dir, temp_filename)

    case File.write(temp_file_path, content) do
      :ok -> {:ok, temp_file_path}
      {:error, reason} -> {:error, "Failed to write temp file: #{inspect(reason)}"}
    end
  end

  defp get_upload_id(%CompanyTemplate{media_asset: nil}), do: {:error, "No media asset found"}

  defp get_upload_id(%CompanyTemplate{media_asset: media_asset}) do
    case media_asset.upload_id do
      nil -> {:error, "No upload_id found in media asset"}
      upload_id -> {:ok, upload_id}
    end
  end

  defp update_template_success(template, variables) do
    with {:ok, updated_template} <-
           CompanyTemplates.update_template(
             template,
             %{variables: variables}
           ) do
      CompanyTemplates.activate_template(updated_template.id)
    end
  end

  defp handle_processing_error(template_id, reason) do
    error_message = format_error(reason)

    case CompanyTemplates.get_template(template_id) do
      %CompanyTemplate{} = template ->
        case CompanyTemplates.update_template(
               template,
               %{status: :failed, error_message: error_message}
             ) do
          {:ok, updated_template} ->
            broadcast_update(updated_template.company_id, updated_template)

          {:error, _changeset} ->
            Logger.error("Failed to update template error status")
        end

      nil ->
        Logger.error("Template not found when handling error: #{template_id}")
    end

    {:error, reason}
  end

  defp format_error({:error, reason}) when is_binary(reason), do: reason
  defp format_error({:error, reason}), do: inspect(reason)
  defp format_error(reason), do: "Failed to process template: #{inspect(reason)}"

  defp broadcast_update(company_id, template) do
    Endpoint.broadcast(
      "company:#{company_id}:templates",
      "template_status_updated",
      template
    )

    :ok
  end
end
