defmodule BemedaPersonalWeb.CompanyJobLive.NewTest do
  use BemedaPersonalWeb.ConnCase, async: false

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import Phoenix.LiveViewTest

  describe "event handlers" do
    setup do
      user = employer_user_fixture()
      company = company_fixture(user)
      %{user: user, company: company}
    end

    test "handles cancel_form event", %{conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/jobs/new")

      # Send the cancel_form event
      send(view.pid, {:cancel_form, :new})

      # Should navigate back to jobs index
      assert_redirect(view, ~p"/company/jobs")
    end

    test "handles unknown events gracefully", %{conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/jobs/new")

      # Send an unknown event
      send(view.pid, :unknown_event)

      # Should remain on the same page and not crash
      assert render(view) =~ "Create Job Post"
    end
  end
end
