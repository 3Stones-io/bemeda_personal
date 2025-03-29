defmodule BemedaPersonalWeb.CompanyApplicantLive.IndexTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import BemedaPersonal.ResumesFixtures
  import Phoenix.LiveViewTest

  setup %{conn: conn} do
    company_user = user_fixture(%{email: "company@example.com"})
    company = company_fixture(company_user)
    job = job_posting_fixture(company)

    applicant_user = user_fixture(%{email: "applicant@example.com"})
    job_application = job_application_fixture(applicant_user, job)
    resume = resume_fixture(applicant_user)

    %{
      conn: conn,
      company: company,
      company_user: company_user,
      job: job,
      applicant: applicant_user,
      job_application: job_application,
      resume: resume
    }
  end

  describe "/companies/:company_id/applicants" do
    test "redirects if user is not logged in", %{conn: conn, company: company} do
      assert {:error, redirect} = live(conn, ~p"/companies/#{company.id}/applicants")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "redirects if user is not admin of the company", %{conn: conn, company: company} do
      other_user = user_fixture(%{email: "other@example.com"})

      assert {:error, {:redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(other_user)
               |> live(~p"/companies/#{company.id}/applicants")

      assert path == ~p"/companies"
      assert flash["error"] == "You don't have permission to access this company."
    end

    test "renders all company applicants page", %{
      conn: conn,
      company_user: user,
      company: company,
      job_application: application
    } do
      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/applicants")

      assert html =~ "Applicants"
      assert html =~ company.name
      assert html =~ "#{application.user.first_name} #{application.user.last_name}"
      assert html =~ application.job_posting.title
    end

    test "allows navigation to applicant details", %{
      conn: conn,
      company_user: user,
      company: company,
      job_application: application
    } do
      conn = log_in_user(conn, user)

      assert {:ok, view, html} = live(conn, ~p"/companies/#{company.id}/applicants")
      assert html =~ "#{application.user.first_name} #{application.user.last_name}"

      assert view
             |> element("#applicant-#{application.id}")
             |> has_element?()
    end
  end
end
