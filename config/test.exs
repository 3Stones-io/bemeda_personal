import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :bemeda_personal, BemedaPersonal.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "bemeda_personal_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :bemeda_personal, BemedaPersonalWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "s3QYVV7NO/JPzUSRbnVgvK6KN0fx2VJv6iprPTgMX9rKfLKTknDHrAjqX/iE0wMm",
  server: false

# In test we don't send emails
config :bemeda_personal, BemedaPersonal.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :bemeda_personal, :tigris,
  access_key_id: "tigris_access_key_id",
  secret_access_key: "tigris_secret_access_key",
  bucket: "tigris-bucket"

# Oban
config :bemeda_personal, Oban, testing: :manual

# Gettext
config :bemeda_personal, BemedaPersonalWeb.Gettext, default_locale: "en"

# Always use mock provider in tests
config :bemeda_personal, :digital_signatures,
  provider: :mock,
  providers: %{
    mock: %{}
  }
