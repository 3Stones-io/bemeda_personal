defmodule BemedaPersonal.Repo do
  use Ecto.Repo,
    otp_app: :bemeda_personal,
    adapter: Ecto.Adapters.Postgres
end
