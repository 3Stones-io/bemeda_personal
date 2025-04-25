Mox.defmock(BemedaPersonal.MuxHelpers.Client.Mock, for: BemedaPersonal.MuxHelpers.Client)
Application.put_env(:bemeda_personal, :mux_helpers, BemedaPersonal.MuxHelpers.Client.Mock)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(BemedaPersonal.Repo, :manual)
