defmodule BemedaPersonal.Documents.ProcessorTest do
  # Cannot be async because we modify global Application config
  use BemedaPersonal.DataCase, async: false

  alias BemedaPersonal.Documents.FileProcessor
  alias BemedaPersonal.Documents.Processor

  @moduletag :processor

  setup do
    # Store the original configuration
    original_processor = Application.get_env(:bemeda_personal, :documents_processor)

    # Use the real FileProcessor for these tests
    Application.put_env(:bemeda_personal, :documents_processor, FileProcessor)

    # Restore original configuration after test
    on_exit(fn ->
      Application.put_env(:bemeda_personal, :documents_processor, original_processor)
    end)

    :ok
  end

  describe "extract_variables/1" do
    test "extracts variables from job offer template with double brackets" do
      doc_path = "test/support/fixtures/files/Job_Offer_Serial_Template.docx"

      assert variables = Processor.extract_variables(doc_path)

      expected_variables = [
        "Title",
        "First_Name",
        "Last_Name",
        "Street",
        "ZipCode",
        "City",
        "Date",
        "Salutation",
        "Job_Title",
        "Client_Company",
        "Work_Location",
        "Contract_Type",
        "Start_Date",
        "Working_Hours",
        "Gross_Salary",
        "Offer_Deadline",
        "Recruiter_Name",
        "Recruiter_Position",
        "Recruiter_Phone",
        "Recruiter_Email",
        "Candidate_Full_Name",
        "Place_Date",
        "Signature"
      ]

      assert Enum.sort(variables) == Enum.sort(expected_variables)
    end
  end

  describe "replace_variables/2" do
    test "replaces variables in the job offer template with provided values" do
      source_path = "test/support/fixtures/files/Job_Offer_Serial_Template.docx"

      values = %{
        "First_Name" => "John",
        "Last_Name" => "Doe",
        "Job_Title" => "Software Engineer",
        "Client_Company" => "ACME Corp",
        "Start_Date" => "2024-02-01"
      }

      assert output_file = Processor.replace_variables(source_path, values)
      assert File.exists?(output_file)

      on_exit(fn ->
        File.rm(output_file)
      end)

      variables = Processor.extract_variables(output_file)

      refute "First_Name" in variables
      refute "Last_Name" in variables
      refute "Job_Title" in variables
      refute "Client_Company" in variables
      refute "Start_Date" in variables

      doc_content = get_content(output_file)

      assert String.contains?(doc_content, "John")
      assert String.contains?(doc_content, "Doe")
      assert String.contains?(doc_content, "Software Engineer")
      assert String.contains?(doc_content, "ACME Corp")
      assert String.contains?(doc_content, "2024-02-01")
    end

    test "replaces unprovided variables with empty strings" do
      source_path = "test/support/fixtures/files/Job_Offer_Serial_Template.docx"

      values = %{
        "First_Name" => "Jane",
        "Last_Name" => "Smith"
      }

      assert output_file = Processor.replace_variables(source_path, values)
      assert File.exists?(output_file)

      on_exit(fn ->
        File.rm(output_file)
      end)

      assert Processor.extract_variables(output_file) == []

      doc_content = get_content(output_file)

      assert String.contains?(doc_content, "Jane")
      assert String.contains?(doc_content, "Smith")

      refute String.contains?(doc_content, "[[")
      refute String.contains?(doc_content, "]]")
    end
  end

  describe "convert_to_pdf/1" do
    test "converts job offer template docx file to pdf" do
      source_path = "test/support/fixtures/files/Job_Offer_Serial_Template.docx"

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
