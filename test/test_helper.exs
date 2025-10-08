# Simple BDD mode detection - check if running BDD tests
bdd_mode? = "--only" in System.argv() and "bdd" in System.argv()

# Exclude feature and bdd tests by default (unless running BDD tests)
ExUnit.start(exclude: [:feature, :bdd])

# BDD-specific setup
if bdd_mode? do
  Cucumber.compile_features!()
  Ecto.Adapters.SQL.Sandbox.mode(BemedaPersonal.Repo, {:shared, self()})
else
  Ecto.Adapters.SQL.Sandbox.mode(BemedaPersonal.Repo, :manual)
end

Application.put_env(:phoenix_test, :base_url, BemedaPersonalWeb.Endpoint.url())

# Define mocks for document processing
Mox.defmock(BemedaPersonal.Documents.MockProcessor, for: BemedaPersonal.Documents.Processor)
Mox.defmock(BemedaPersonal.Documents.MockStorage, for: BemedaPersonal.Documents.Storage)

# Configure application to use mocks
Application.put_env(
  :bemeda_personal,
  :documents_processor,
  BemedaPersonal.Documents.MockProcessor
)

Application.put_env(:bemeda_personal, :documents_storage, BemedaPersonal.Documents.MockStorage)

# Set default stubs for mocks to avoid crashes in async tests
# Tests can override these with expect/2
Mox.stub(BemedaPersonal.Documents.MockProcessor, :extract_variables, fn _path -> [] end)

Mox.stub(BemedaPersonal.Documents.MockProcessor, :replace_variables, fn path, _values ->
  # Mimic the real behavior of creating a *_processed.docx file
  dir = Path.dirname(path)
  ext = Path.extname(path)
  filename = Path.basename(path, ext)
  Path.join(dir, "#{filename}_processed#{ext}")
end)

Mox.stub(BemedaPersonal.Documents.MockProcessor, :convert_to_pdf, fn path ->
  String.replace(path, ".docx", ".pdf")
end)

Mox.stub(BemedaPersonal.Documents.MockStorage, :download_file, fn _key -> {:error, :not_found} end)

Mox.stub(BemedaPersonal.Documents.MockStorage, :upload_file, fn _key, _content, _type -> :ok end)
