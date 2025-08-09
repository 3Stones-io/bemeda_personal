defmodule BemedaPersonalWeb.Features.TestRegistrationHelperTest do
  @moduledoc """
  Test the updated registration helpers
  """

  use BemedaPersonalWeb.FeatureCase, async: false

  import BemedaPersonal.FeatureHelpers

  @moduletag :feature

  describe "registration helpers" do
    test "register_job_seeker helper works", %{conn: conn} do
      conn
      |> register_job_seeker()
      # Should be on home page after registration
      # Or whatever text is on home page
      |> assert_has("*", text: "BemedaPersonal")
    end
  end
end
