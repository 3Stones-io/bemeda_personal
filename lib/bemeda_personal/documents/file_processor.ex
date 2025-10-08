defmodule BemedaPersonal.Documents.FileProcessor do
  @moduledoc """
  Implementation of the document processor behaviour.
  """

  alias BemedaPersonal.Documents.Processor

  @behaviour Processor

  @impl Processor
  def extract_variables(document_path) do
    work_dir = System.tmp_dir!()
    extract_dir = Path.join(work_dir, "extracted")
    File.mkdir_p!(extract_dir)

    case document_path
         |> String.to_charlist()
         |> :zip.unzip([{:cwd, String.to_charlist(extract_dir)}]) do
      {:ok, _extracted_files_list} ->
        doc_xml_path = Path.join(extract_dir, "word/document.xml")

        header_files =
          [extract_dir, "word", "header*.xml"]
          |> Path.join()
          |> Path.wildcard()

        footer_files =
          [extract_dir, "word", "footer*.xml"]
          |> Path.join()
          |> Path.wildcard()

        documents = [doc_xml_path] ++ header_files ++ footer_files

        variables =
          documents
          |> Enum.flat_map(&extract_variables_from_file/1)
          |> Enum.uniq()

        File.rm_rf(extract_dir)
        File.rm_rf(work_dir)

        variables

      {:error, reason} ->
        File.rm_rf(extract_dir)
        File.rm_rf(work_dir)
        raise "Failed to extract document: #{inspect(reason)}"
    end
  end

  @impl Processor
  def replace_variables(document_path, values) do
    output_file = output_file_path(document_path)

    extract_dir = extract_document(document_path)

    extract_dir
    |> find_document_files()
    |> process_document_files(values)

    create_modified_document(extract_dir, output_file)

    File.rm_rf(extract_dir)

    output_file
  end

  @impl Processor
  def convert_to_pdf(document_path) do
    output_dir = Path.dirname(document_path)
    document_path_escaped = String.replace(document_path, "\"", "\\\"")

    cmd =
      ~s|soffice --headless --convert-to pdf --outdir "#{output_dir}" "#{document_path_escaped}"|

    {_output, 0} = System.shell(cmd)

    basename = Path.basename(document_path, ".docx")
    Path.join(output_dir, "#{basename}.pdf")
  end

  defp replace_variables_in_content(content, values) do
    Enum.reduce(values, content, fn {variable, value}, acc ->
      simple_pattern = ~r/\[\[#{Regex.escape(variable)}\]\]/
      acc = Regex.replace(simple_pattern, acc, value)

      xml_split_pattern = ~r/\[\[([^]]*?<w:t>#{Regex.escape(variable)}<\/w:t>[^]]*?)\]\]/s
      Regex.replace(xml_split_pattern, acc, value)
    end)
  end

  defp remove_placeholders(content) do
    Regex.replace(~r/\[\[([^\[\]]+)\]\]/, content, fn _full_match, _variable -> "" end)
  end

  defp output_file_path(document_path) do
    dir = Path.dirname(document_path)
    ext = Path.extname(document_path)
    filename = Path.basename(document_path, ext)
    Path.join(dir, "#{filename}_processed#{ext}")
  end

  defp extract_variables_from_file(file_path) do
    content = File.read!(file_path)

    ~r/\[\[([^\[\]]+)\]\]/
    |> Regex.scan(content)
    |> Stream.map(fn [_match, capture] -> capture end)
    |> Stream.map(&remove_xml_tags/1)
    |> Stream.map(&String.trim/1)
    |> Stream.reject(&(&1 == ""))
    |> Stream.reject(&(&1 == "FORMTEXT"))
    |> Enum.to_list()
  end

  defp remove_xml_tags(variable) do
    variable
    |> String.replace(~r/<[^>]*>/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp extract_document(document_path) do
    extract_dir = Path.join(System.tmp_dir!(), "extracted")
    File.mkdir_p!(extract_dir)

    case document_path
         |> String.to_charlist()
         |> :zip.unzip([{:cwd, String.to_charlist(extract_dir)}]) do
      {:ok, _extracted_files_list} ->
        extract_dir

      {:error, reason} ->
        File.rm_rf(extract_dir)
        raise "Failed to extract document: #{inspect(reason)}"
    end
  end

  defp find_document_files(extract_dir) do
    doc_xml_path = Path.join(extract_dir, "word/document.xml")

    header_files =
      [extract_dir, "word", "header*.xml"]
      |> Path.join()
      |> Path.wildcard()

    footer_files =
      [extract_dir, "word", "footer*.xml"]
      |> Path.join()
      |> Path.wildcard()

    [doc_xml_path] ++ header_files ++ footer_files
  end

  defp process_document_files(documents, values) do
    Enum.each(documents, fn file_path ->
      content = File.read!(file_path)

      updated_content =
        content
        |> replace_variables_in_content(values)
        |> remove_placeholders()

      File.write!(file_path, updated_content)
    end)
  end

  defp create_modified_document(extract_dir, output_file) do
    files = collect_document_files(extract_dir)

    output_file
    |> String.to_charlist()
    |> :zip.create(files)
  end

  defp collect_document_files(extract_dir) do
    [extract_dir, "**/*"]
    |> Path.join()
    |> Path.wildcard(match_dot: true)
    |> Stream.filter(&File.regular?/1)
    |> Stream.map(fn file_path ->
      path =
        file_path
        |> Path.relative_to(extract_dir)
        |> String.to_charlist()

      content = File.read!(file_path)

      {path, content}
    end)
    |> Enum.to_list()
  end
end
