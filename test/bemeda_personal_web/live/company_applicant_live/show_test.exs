defmodule BemedaPersonalWeb.CompanyApplicantLive.ShowTest do
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
      conn: conn,
      company_user: user,
      company: company,
      job_application: application
    } do
      conn = log_in_user(conn, user)

      {:ok, view, _html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      assert view |> has_element?("#applicant-tags")

      view
      |> element("#applicant-tags form")
      |> render_change(%{name: "qualified"})

      view
      |> element("#applicant-tags form")
      |> render_submit(%{name: "qualified"})

      html = render(view)
      assert html =~ "qualified"
    end

    test "allows removing tags from the application", %{
      conn: conn,
      company_user: user,
      company: company,
      job_application: application
    } do
      conn = log_in_user(conn, user)

      # First, add a tag
      {:ok, view, _html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      view
      |> element("#applicant-tags form")
      |> render_submit(%{name: "qualified"})

      # Then get the tag's ID from the rendered view
      html = render(view)
      assert html =~ "qualified"

      # Find and click the remove button for the tag
      [{tag_id, _}] =
        Regex.scan(~r/data-tag-id="([^"]+)"/, html)
        |> Enum.map(fn [_, id] -> {id, nil} end)

      view
      |> element("button[phx-click='remove-tag'][phx-value-tag-id='#{tag_id}']")
      |> render_click()

      # Verify the tag is gone
      html = render(view)
      refute html =~ "qualified"
    end
  end
end
