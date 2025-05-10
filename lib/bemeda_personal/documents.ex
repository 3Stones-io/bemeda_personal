defmodule BemedaPersonal.Documents do
  @moduledoc """
  The Documents context.
  Handles document processing operations.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Chat
  alias BemedaPersonal.Documents.Processor
  alias BemedaPersonal.Documents.Storage
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Media

  require Logger

  @type message_id :: String.t()
  @type reason :: String.t()
  @type variable :: String.t()
  @type variables :: map()

  @doc """
  Extracts variables from a document template.

  ## Examples

    iex> Documents.extract_template_variables("123")
    {:ok, ["variable1", "variable2"]}

    iex> Documents.extract_template_variables("123")
    {:error, "Message or media asset not found"}

  """
  @spec extract_template_variables(message_id()) :: {:ok, [variable()]} | {:error, reason()}
  def extract_template_variables(message_id) do
    with %Media.MediaAsset{upload_id: upload_id} <-
           Media.get_media_asset_by_message_id(message_id),
         {:ok, doc_path} <- download_document(upload_id),
         variables <- Processor.extract_variables(doc_path) do
      {:ok, variables}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Generates a PDF from a document template.

  ## Examples

    iex> Documents.generate_pdf(
    ...>   "123",
    ...>   %{"variable1" => "value1", "variable2" => "value2"},
    ...>   user,
    ...>   job_application
    ...> )
    {:ok, %Message{}}

  """
  @spec generate_pdf(message_id(), variables(), Accounts.User.t(), Jobs.JobApplication.t()) ::
          {:ok, Chat.Message.t()} | {:error, reason()}
  def generate_pdf(message_id, variables, user, job_application) do
    with %Media.MediaAsset{upload_id: upload_id} = media_asset <-
           Media.get_media_asset_by_message_id(message_id),
         {:ok, doc_path} <- download_document(upload_id),
         doc_path <- Processor.replace_variables(doc_path, variables),
         pdf_path <- Processor.convert_to_pdf(doc_path),
         {:ok, pdf_id} <- upload_pdf(pdf_path) do
      base_name = Path.rootname(media_asset.file_name)

      Chat.create_message_with_media(
        user,
        job_application,
        %{
          "content" => "Generated document",
          "media_data" => %{
            "file_name" => "#{base_name}.pdf",
            "type" => "application/pdf",
            "status" => :uploaded,
            "upload_id" => pdf_id
          }
        }
      )
    else
      nil -> {:error, "Message or media asset not found"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp download_document(upload_id) do
    temp_dir = System.tmp_dir!()
    local_path = Path.join(temp_dir, "template_#{upload_id}.docx")

    local_path
    |> Path.dirname()
    |> File.mkdir_p!()

    case Storage.download_file(upload_id) do
      {:ok, "<?xml" <> _rest} ->
        {:error, "Invalid document format"}

      {:ok, content} ->
        File.write!(local_path, content)
        {:ok, local_path}

      {:error, reason} ->
        {:error, "Failed to download document: #{inspect(reason)}"}
    end
  end

  defp upload_pdf(pdf_path) do
    pdf_id = Ecto.UUID.generate()

    with {:ok, content} <- File.read(pdf_path),
         :ok <- Storage.upload_file(pdf_id, content, "application/pdf") do
      {:ok, pdf_id}
    else
      {:error, reason} -> {:error, "Failed to upload PDF: #{inspect(reason)}"}
    end
  end
end
