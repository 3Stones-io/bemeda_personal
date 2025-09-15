defmodule BemedaPersonalWeb.Features.TestRegistrationHelperTest do
  @moduledoc """
  Test the updated registration helpers
  """

  use BemedaPersonalWeb.FeatureCase, async: true

  import BemedaPersonal.FeatureHelpers

  @moduletag :feature

  describe "registration helpers" do
    test "registration page loads with account type selection", %{conn: conn} do
      conn
      |> PhoenixTest.Playwright.clear_cookies()
      # Explicitly log out any existing user first
      |> visit(~p"/users/log_out")
      |> visit(~p"/users/register")
      |> assert_path("/users/register")
      |> assert_has("main")
      # Should see both account type options
      |> assert_has("*", text: "Join as a job seeker or employer")
      |> assert_has("*", text: "Employer")
      |> assert_has("*", text: "Medical Personnel")
    end
  end
end
