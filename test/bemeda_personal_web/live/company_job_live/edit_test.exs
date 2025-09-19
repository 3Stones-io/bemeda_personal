defmodule BemedaPersonalWeb.CompanyJobLive.EditTest do
  use BemedaPersonalWeb.ConnCase, async: false

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobPostingsFixtures
  import Phoenix.LiveViewTest

  describe "edit job posting" do
    setup do
      employer = employer_user_fixture()
      company = company_fixture(employer)
      job_posting = job_posting_fixture(company)

      %{employer: employer, company: company, job_posting: job_posting}
    end

    test "authorized employer can access edit page", %{
      conn: conn,
      employer: employer,
      job_posting: job_posting
    } do
      conn = log_in_user(conn, employer)

      {:ok, _view, html} = live(conn, ~p"/company/jobs/#{job_posting.id}/edit")

      assert html =~ "Edit Job"
    end

    test "unauthorized access redirects with error message", %{
      conn: conn,
      job_posting: job_posting
    } do
      # Create another employer who doesn't own the job posting
      other_employer = employer_user_fixture()
      _other_company = company_fixture(other_employer)
      conn = log_in_user(conn, other_employer)

      # Navigate to the edit page for a job they don't own
      assert {:error, {:live_redirect, %{to: "/company/jobs", flash: flash}}} =
               live(conn, ~p"/company/jobs/#{job_posting.id}/edit")

      # Should show error flash message (scope-based authorization message)
      assert flash["error"] =~ "Job posting not found or not authorized"
    end

    test "handles cancel form event", %{conn: conn, employer: employer, job_posting: job_posting} do
      conn = log_in_user(conn, employer)

      {:ok, view, _html} = live(conn, ~p"/company/jobs/#{job_posting.id}/edit")

      # Simulate cancel form event
      send(view.pid, {:cancel_form, :some_action})

      # The view should navigate to company jobs page
      flash = assert_redirect(view, ~p"/company/jobs")
      assert flash == %{}
    end

    test "handles unknown info messages gracefully", %{
      conn: conn,
      employer: employer,
      job_posting: job_posting
    } do
      conn = log_in_user(conn, employer)

      {:ok, view, _html} = live(conn, ~p"/company/jobs/#{job_posting.id}/edit")

      # Simulate unknown message
      send(view.pid, {:unknown_message, :some_data})

      # Should not crash - view should still be accessible
      assert render(view) =~ "Edit Job"
    end
  end
end
