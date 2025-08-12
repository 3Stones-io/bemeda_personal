defmodule BemedaPersonalWeb.Features.SimpleTest do
  @moduledoc """
  Ultra-simple test to verify PhoenixTest.Playwright infrastructure is working.
  """

  use BemedaPersonalWeb.FeatureCase, async: true

  @moduletag :feature

  describe "basic infrastructure test" do
    @tag viewport: {1280, 720}
    test "basic page visit works", %{conn: conn} do
      conn
      |> visit(~p"/")
      |> assert_has("html")
    end

    @tag viewport: {1280, 720}
    test "page content loads with basic HTML structure", %{conn: conn} do
      # Just check that we get some basic HTML structure back
      # The home page uses layout: false so no main element, check for content instead
      conn
      |> visit(~p"/")
      |> assert_has("html")
      # Home page has h1 with "Find Your Next" text
      |> assert_has("h1")
      |> assert_path("/")
    end
  end
end
