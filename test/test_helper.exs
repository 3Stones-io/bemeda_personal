# Exclude feature and bdd tests by default
ExUnit.start(exclude: [:feature, :bdd])

# Compile Cucumber features and set sandbox mode based on test type
# BDD tests use shared mode for Cucumber-generated test modules
# Regular tests use manual mode (default)
if "--include" in System.argv() and "bdd" in System.argv() do
  Cucumber.compile_features!()
  Ecto.Adapters.SQL.Sandbox.mode(BemedaPersonal.Repo, {:shared, self()})
else
  Ecto.Adapters.SQL.Sandbox.mode(BemedaPersonal.Repo, :manual)
end

Application.put_env(:phoenix_test, :base_url, BemedaPersonalWeb.Endpoint.url())

Mox.defmock(BemedaPersonal.Documents.MockProcessor, for: BemedaPersonal.Documents.Processor)

Application.put_env(
  :bemeda_personal,
  :documents_processor,
  BemedaPersonal.Documents.MockProcessor
)

Mox.defmock(BemedaPersonal.Documents.MockStorage, for: BemedaPersonal.Documents.Storage)
Application.put_env(:bemeda_personal, :documents_storage, BemedaPersonal.Documents.MockStorage)
