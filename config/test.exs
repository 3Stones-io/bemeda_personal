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
  hostname: System.get_env("DATABASE_HOST", "localhost"),
  database: "bemeda_personal_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  # Dynamic pool sizing based on CPU cores
  pool_size: min(System.schedulers_online() * 2, 20),
  # Increased queue target for async tests
  queue_target: 5000,
  # Longer queue interval
  queue_interval: 10_000,
  # Increased timeout for complex tests
  timeout: 60_000,
  # Disable parallel preloading to prevent DBConnection.OwnershipError
  # Task processes spawned by Ecto.Repo.Preloader don't inherit database ownership
  ownership_timeout: 300_000

# Only start server for feature tests
server_enabled? = System.get_env("FEATURE_TESTS") == "true"

config :bemeda_personal, BemedaPersonalWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT_TEST") || "4205")],
  secret_key_base: "s3QYVV7NO/JPzUSRbnVgvK6KN0fx2VJv6iprPTgMX9rKfLKTknDHrAjqX/iE0wMm",
  server: server_enabled?

# Enable SQL Sandbox for concurrent testing
config :bemeda_personal, :sql_sandbox, true

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

# PhoenixTest.Playwright configuration
config :phoenix_test,
  driver: PhoenixTest.Playwright,
  endpoint: BemedaPersonalWeb.Endpoint,
  otp_app: :bemeda_personal,
  playwright: [
    browser: :chromium,
    browser_launch_timeout: 30_000,
    headless: System.get_env("PW_HEADLESS", "true") == "true",
    js_logger: false,
    screenshot: System.get_env("PW_SCREENSHOT", "true") == "true",
    timeout: System.get_env("PW_TIMEOUT", "2000") |> String.to_integer(),
    trace: System.get_env("PW_TRACE", "false") == "true"
  ]

# Gettext
config :bemeda_personal, BemedaPersonalWeb.Gettext, default_locale: "en"

# Always use mock provider in tests
config :bemeda_personal, :digital_signatures,
  provider: :mock,
  providers: %{
    mock: %{}
  }

config :bemeda_personal, :admin,
  password: "admin",
  username: "admin"
