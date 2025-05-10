defmodule BemedaPersonal.Documents.ProcessorTest do
  use BemedaPersonal.DataCase, async: false

  alias BemedaPersonal.Documents.FileProcessor
  alias BemedaPersonal.Documents.MockProcessor
  alias BemedaPersonal.Documents.Processor

  @moduletag :processor

  setup do
    on_exit(fn ->
      Application.put_env(:bemeda_personal, :documents_processor, MockProcessor)
    end)

    Application.put_env(:bemeda_personal, :documents_processor, FileProcessor)

    :ok
  end

  describe "extract_variables/1" do
    test "extracts variables from service contract document" do
      doc_path = "test/support/fixtures/files/CLIENT SERVICE CONTRACT 29-01-22.docx"

      assert variables = Processor.extract_variables(doc_path)

      expected_variables = [
        "enter agency name",
        "enter contractor name",
        "enter contractor address",
        "enter city, state, zip for contractor",
        "enter email address for contractor",
        "enter contractor telephone no.",
        "enter contractor fax no.",
        "provide detailed description of contract purpose",
        "Insert table with deliverable due dates here",
        "insert name of contract manager",
        "enter start date",
        "enter contract end date",
        "write out the full dollar amount",
        "insert rates and/or terms of compensation",
        "enter contract manager's name",
        "enter name of Contractor",
        "enter Contractor address",
        "enter Contractor city, state, zip",
        "enter name of Department",
        "enter Department address",
        "enter Department city, state, zip",
        "ENTER CONTACTOR NAME",
        "ENTER DEPARTMENT NAME",
        "is binding on all parties",
        "shall/shall not be admissible in any succeeding judicial or quasi-judicial proceeding concerning the Contract.  Parties agree that the DRB shall proceed with any action in a judicial or quasi-judicial tribunal.",
        "Department/Director of Department or his or her designee",
        "shall/shall not be",
        "insert the name of your agency",
        "insert the name of the entity you are contracting with",
        "insert start date",
        "LIST AGREEMENT(S) THE ADDENDUM APPLIES TO",
        "Insert Agency Name",
        "Insert Name",
        "identify specific activity or activities",
        "CONTRACTOR'S NAME",
        "DEPARTMENT NAME"
      ]

      assert Enum.sort(variables) == Enum.sort(expected_variables)
    end

    test "extracts variables from freelance contract document" do
      doc_path = "test/support/fixtures/files/Копия \"Freelance Contract\".docx"

      assert variables = Processor.extract_variables(doc_path)

      expected_variables = [
        "Sender.FirstName",
        "Sender.LastName",
        "Sender.Company",
        "Sender.StreetAddress",
        "Sender.City",
        "Sender.Country",
        "Sender.PostalCode",
        "Sender.Phone",
        "Sender.Email",
        "Client.FirstName",
        "Client.LastName",
        "Client.Company",
        "Client.StreetAddress",
        "Client.City",
        "Client.Country",
        "Client.PostalCode",
        "Client.Phone",
        "Client.Email",
        "INSERT THE NAME OF THE PUBLICATION COMPANY",
        "SPECIFY THE STATE",
        "SPECIFY PRINCIPAL PLACE OF BUSINESS OR ADDRESS",
        "INSERT THE NAME OF THE WRITER",
        "INSERT THE STATUS",
        "INSERT THE NATIONALITY",
        "INSERT THE ADDRESS",
        "INSERT THE WEBSITE OF THE PUBLICATION COMPANY",
        "INSERT THE SUBJECTS FOR THE WRITTEN ARTICLES",
        "INSERT THE DEADLINE SCHEDULE",
        "USD 0.00",
        "Client Name",
        "Client Signature",
        "Date"
      ]

      assert Enum.sort(variables) == Enum.sort(expected_variables)
    end
  end

  describe "replace_variables/2" do
    test "replaces variables in the service contract document with provided values" do
      source_path = "test/support/fixtures/files/CLIENT SERVICE CONTRACT 29-01-22.docx"

      values = %{
        "enter agency name" => "ACME Corp",
        "enter contractor name" => "John Doe"
      }

      assert output_file = Processor.replace_variables(source_path, values)
      assert File.exists?(output_file)

      on_exit(fn ->
        File.rm(output_file)
      end)

      variables = Processor.extract_variables(output_file)

      refute "enter agency name" in variables
      refute "enter contractor name" in variables

      doc_content = get_content(output_file)

      assert String.contains?(doc_content, "ACME Corp")
      assert String.contains?(doc_content, "John Doe")
    end

    test "replaces variables in the freelance contract document with provided values" do
      source_path = "test/support/fixtures/files/Копия \"Freelance Contract\".docx"

      values = %{
        "Sender.FirstName" => "John",
        "Sender.LastName" => "Doe",
        "Sender.Company" => "ACME Corp",
        "Client.FirstName" => "Jane",
        "Client.LastName" => "Smith"
      }

      assert output_file = Processor.replace_variables(source_path, values)
      assert File.exists?(output_file)

      on_exit(fn ->
        File.rm(output_file)
      end)

      variables = Processor.extract_variables(output_file)

      refute "Sender.FirstName" in variables
      refute "Sender.LastName" in variables
      refute "Sender.Company" in variables
      refute "Client.FirstName" in variables
      refute "Client.LastName" in variables

      doc_content = get_content(output_file)

      assert String.contains?(doc_content, "John")
      assert String.contains?(doc_content, "Doe")
      assert String.contains?(doc_content, "ACME Corp")
      assert String.contains?(doc_content, "Jane")
      assert String.contains?(doc_content, "Smith")
    end
  end

  describe "convert_to_pdf/1" do
    test "converts service contract docx file to pdf" do
      source_path = "test/support/fixtures/files/CLIENT SERVICE CONTRACT 29-01-22.docx"

      pdf_path = Processor.convert_to_pdf(source_path)
      assert File.exists?(pdf_path)
      assert Path.extname(pdf_path) == ".pdf"

      on_exit(fn ->
        File.rm(pdf_path)
      end)
    end

    test "converts freelance contract docx file to pdf" do
      source_path = "test/support/fixtures/files/Копия \"Freelance Contract\".docx"

      pdf_path = Processor.convert_to_pdf(source_path)
      assert File.exists?(pdf_path)
      assert Path.extname(pdf_path) == ".pdf"

      on_exit(fn ->
        File.rm(pdf_path)
      end)
    end
  end

  defp get_content(file_path) do
    work_dir = System.tmp_dir!()
    extract_dir = Path.join(work_dir, "test_extract")
    File.mkdir_p!(extract_dir)

    on_exit(fn ->
      File.rm_rf(extract_dir)
    end)

    {:ok, _files} =
      file_path
      |> String.to_charlist()
      |> :zip.unzip([{:cwd, String.to_charlist(extract_dir)}])

    doc_xml_path = Path.join(extract_dir, "word/document.xml")
    File.read!(doc_xml_path)
  end
end
