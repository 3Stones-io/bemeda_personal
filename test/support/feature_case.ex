defmodule BemedaPersonalWeb.FeatureCase do
  @moduledoc """
  This module defines the setup for feature tests using browser automation.

  Based on the production-ready ElixirDrops pattern with proper database sandbox
  configuration for async feature testing with PhoenixTest.Playwright.

  Supports flexible async configuration:
  - `use BemedaPersonalWeb.FeatureCase` - Uses async: true (optimized default)
  - `use BemedaPersonalWeb.FeatureCase, async: true` - Enable async (recommended for performance)
  - `use BemedaPersonalWeb.FeatureCase, async: false` - Force sequential execution

  Most tests should use async: true for 3-5x performance improvement. 
  Use async: false only when debugging race conditions or testing scenarios 
  that require sequential database operations.
  """

  use ExUnit.CaseTemplate

  using opts do
    # Don't override async setting - let each test decide
    # Most feature tests use async: false to avoid database ownership issues

    quote do
      # Use PhoenixTest.Playwright.Case with the async setting from the test
      use PhoenixTest.Playwright.Case, unquote(opts)
      use BemedaPersonalWeb, :verified_routes

      # Use ExUnit default timeout (60 seconds) for feature tests

      # Import conveniences for testing
      import BemedaPersonal.AccountsFixtures
      import BemedaPersonal.CompaniesFixtures
      import BemedaPersonal.FeatureHelpers
      import BemedaPersonal.JobApplicationsFixtures
    end
  end

  # PhoenixTest.Playwright.Case handles all database setup automatically
  # The LiveAcceptance hook in router.ex handles LiveView database access
  # Phoenix.Ecto.SQL.Sandbox plug in endpoint.ex handles controller database access
end
