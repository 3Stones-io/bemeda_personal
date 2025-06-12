defmodule BemedaPersonal.Documents.Processor do
  @moduledoc """
  Handles document processing, including variable replacement in docx files
  and conversion to PDF.
  """

  alias BemedaPersonal.Documents.FileProcessor

  @type file_path :: String.t()
  @type variable :: String.t()
  @type variables :: map()

  @callback extract_variables(file_path()) :: [variable()]
  @callback replace_variables(file_path(), variables()) :: file_path()
  @callback convert_to_pdf(file_path()) :: file_path()

  @doc """
  Extracts all variable placeholders from a document.
  The variables are the text within double square brackets.

  ## Examples

      iex> Processor.extract_variables("test/support/fixtures/files/Job_Offer_Serial_Template.docx")
      ["Employee_Name", "Company_Name", "Start_Date", ...]

  """
  @spec extract_variables(file_path()) :: [variable()]
  def extract_variables(document_path) do
    impl().extract_variables(document_path)
  end

  @doc """
  Replaces variables in a document with provided values.
  Returns path to a new document with replaced variables.

  ## Examples

      iex> Processor.replace_variables(
      ...>   "path/to/document.docx",
      ...>   %{"Employee_Name" => "John Doe", "Company_Name" => "ACME Corp"}
      ...> )
      "path/to/processed_document.docx"

  """
  @spec replace_variables(file_path(), map()) :: file_path()
  def replace_variables(document_path, values) do
    impl().replace_variables(document_path, values)
  end

  @doc """
  Converts a DOCX document to PDF using LibreOffice.
  Returns the path to the generated PDF file.

  ## Examples

      iex> Processor.convert_to_pdf("path/to/document.docx")
      "path/to/document.pdf"

  """
  @spec convert_to_pdf(file_path()) :: file_path()
  def convert_to_pdf(document_path) do
    impl().convert_to_pdf(document_path)
  end

  defp impl do
    Application.get_env(:bemeda_personal, :documents_processor, FileProcessor)
  end
end
