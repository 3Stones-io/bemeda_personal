defmodule BemedaPersonalWeb.Features.SimpleCalendarTest do
  @moduledoc """
  Simplified feature test to verify basic calendar functionality.
  """

  use BemedaPersonalWeb.FeatureCase, async: false

  import BemedaPersonal.SchedulingFixtures

  describe "Basic Calendar Access" do
    @tag :feature
    test "employer can access company dashboard", %{conn: conn} do
      session = visit(conn, "/")
      %{employer: employer} = interview_fixture_with_scope()

      session
      |> sign_in_user(employer)
      |> visit(~p"/company")
      |> wait_for_element("body")
      # Use structural assertion instead of text to avoid language issues
      |> assert_has("section#company-dashboard")
    end

    @tag :feature
    test "employer can see schedule tab", %{conn: conn} do
      session = visit(conn, "/")
      %{employer: employer} = interview_fixture_with_scope()

      session
      |> sign_in_user(employer)
      |> visit(~p"/company")
      |> wait_for_element("nav")
      # Use structural assertion - check for the tab button instead of text
      |> assert_has("button[phx-value-tab=\"schedule\"]")
    end
  end
end
