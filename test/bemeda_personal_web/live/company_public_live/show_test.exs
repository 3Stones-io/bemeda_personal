defmodule BemedaPersonalWeb.CompanyPublicLive.ShowTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import Phoenix.LiveViewTest

  describe "Show" do
    setup %{conn: conn} do
      user = user_fixture()
      company = company_fixture(user)
      job_posting = job_posting_fixture(company)

      %{conn: conn, company: company, user: user, job_posting: job_posting}
    end

    test "renders company public profile for unauthenticated users", %{
      company: company,
      conn: conn,
      job_posting: job_posting
    } do
      {:ok, _view, html} = live(conn, ~p"/company/#{company.id}")

      # Company information is displayed
      assert html =~ company.name
      assert html =~ company.industry
      assert html =~ company.location
      assert html =~ company.size

      # Website URL
      assert html =~ company.website_url

      # Job listings
      assert html =~ job_posting.title
    end

    test "renders company profile for authenticated users", %{
      company: company,
      conn: conn,
      user: user
    } do
      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/#{company.id}")

      # Company information is displayed
      assert html =~ company.name
      assert html =~ company.industry
    end

    test "displays correct job count", %{
      company: company,
      conn: conn
    } do
      # Create a second job for the company
      job_posting_fixture(company)

      {:ok, _view, html} = live(conn, ~p"/company/#{company.id}")

      # Two jobs should be listed
      assert html =~ "Open Positions"
      assert html =~ "2"
    end

    test "allows navigation to all jobs page", %{
      company: company,
      conn: conn
    } do
      {:ok, view, _html} = live(conn, ~p"/company/#{company.id}")

      # Click view all jobs link
      {:ok, _view, html} =
        view
        |> element("a", "View All Jobs")
        |> render_click()
        |> follow_redirect(conn, ~p"/company/#{company.id}/jobs")

      assert html =~ "Jobs at #{company.name}"
    end
  end
end
