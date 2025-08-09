ExUnit.start(exclude: [:feature])
Ecto.Adapters.SQL.Sandbox.mode(BemedaPersonal.Repo, :manual)

Application.put_env(:phoenix_test, :base_url, BemedaPersonalWeb.Endpoint.url())

Mox.defmock(BemedaPersonal.Documents.MockProcessor, for: BemedaPersonal.Documents.Processor)

Application.put_env(
  :bemeda_personal,
  :documents_processor,
  BemedaPersonal.Documents.MockProcessor
)

Mox.defmock(BemedaPersonal.Documents.MockStorage, for: BemedaPersonal.Documents.Storage)
Application.put_env(:bemeda_personal, :documents_storage, BemedaPersonal.Documents.MockStorage)
