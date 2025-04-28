defmodule BemedaPersonalWeb.CompanyApplicantLive.ShowTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import BemedaPersonal.ResumesFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Jobs

  setup %{conn: conn} do
    company_user = user_fixture(%{email: "company@example.com"})
    company = company_fixture(company_user)
    job = job_posting_fixture(company)

    applicant_user =
      user_fixture(%{
        email: "applicant@example.com",
        first_name: "Jane",
        last_name: "Applicant"
      })

    job_application = job_application_fixture(applicant_user, job)
    resume = resume_fixture(applicant_user, %{is_public: true})

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

  describe "/companies/:company_id/applicant/:id" do
    test "redirects if user is not logged in", %{
      conn: conn,
      company: company,
      job_application: application
    } do
      assert {:error, redirect} =
               live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "redirects if user is not admin of the company", %{
      conn: conn,
      company: company,
      job_application: application
    } do
      other_user = user_fixture(%{email: "other@example.com"})

      assert {:error, {:redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(other_user)
               |> live(~p"/companies/#{company.id}/applicant/#{application.id}")

      assert path == ~p"/companies"
      assert flash["error"] == "You don't have permission to access this company."
    end

    test "renders applicant details page", %{
      conn: conn,
      company_user: user,
      company: company,
      job_application: application,
      job: job
    } do
      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/applicant/#{application.id}")

      applicant_name = "#{application.user.first_name} #{application.user.last_name}"

      assert html =~ applicant_name
      assert html =~ job.title
      assert html =~ application.cover_letter
    end

    test "displays resume information when available", %{
      conn: conn,
      company_user: user,
      company: company,
      job_application: application
    } do
      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/applicant/#{application.id}")

      applicant_name = "#{application.user.first_name} #{application.user.last_name}"
      assert html =~ applicant_name
      assert html =~ "View Resume"
    end

    test "allows user to navigate to the applicant chat page", %{
      company_user: user,
      company: company,
      conn: conn,
      job_application: application,
      job: job
    } do
      conn = log_in_user(conn, user)

      assert {:ok, view, _html} =
               live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      assert {:error, {:live_redirect, %{to: path}}} =
               view
               |> element("a", "Chat with Applicant")
               |> render_click()

      assert path =~ ~p"/jobs/#{job.id}/job_applications/#{application.id}"
    end

    test "provides a link back to applicants list", %{
      conn: conn,
      company_user: user,
      company: company,
      job_application: application
    } do
      conn = log_in_user(conn, user)

      assert {:ok, view, _html} =
               live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      assert view
             |> element("a", "Back to Applicants")
             |> has_element?()
    end

    test "allows adding tags to the application", %{
      company_user: user,
      company: company,
      conn: conn,
      job_application: application
    } do
      conn = log_in_user(conn, user)

      {:ok, view, _html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      assert has_element?(view, "#applicant-tags")

      view
      |> element("#applicant-tags")
      |> render_hook("add-tag", %{name: "qualified"})

      html = render(view)
      assert html =~ "qualified"

      job_application = Jobs.get_job_application!(application.id)
      assert "qualified" in Enum.map(job_application.tags, & &1.name)
    end

    test "allows removing tags from the application", %{
      company_user: user,
      company: company,
      conn: conn,
      job_application: application
    } do
      conn = log_in_user(conn, user)

      {:ok, application} =
        Jobs.add_tags_to_job_application(application, ["qualified", "urgent"])

      tag_id =
        application.tags
        |> Enum.find(&(&1.name == "qualified"))
        |> Map.get(:id)

      {:ok, view, html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      assert html =~ "qualified"
      assert html =~ "urgent"

      html2 =
        view
        |> element("#remove-tag-#{tag_id}")
        |> render_click()

      refute html2 =~ "qualified"
      assert html2 =~ "urgent"

      job_application = Jobs.get_job_application!(application.id)
      refute "qualified" in Enum.map(job_application.tags, & &1.name)
    end
  end
end
