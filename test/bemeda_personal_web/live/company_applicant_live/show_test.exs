defmodule BemedaPersonalWeb.CompanyApplicantLive.ShowTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import BemedaPersonal.RatingsFixtures
  import BemedaPersonal.ResumesFixtures
  import Phoenix.LiveViewTest

  setup %{conn: conn} do
    company_user = user_fixture(confirmed: true)
    company = company_fixture(company_user)
    job = job_posting_fixture(company)

    applicant_user =
      user_fixture(
        confirmed: true,
        email: "applicant@example.com",
        first_name: "Jane",
        last_name: "Applicant"
      )

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
      other_user = user_fixture(confirmed: true)

      assert {:error, {:redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(other_user)
               |> live(~p"/companies/#{company.id}/applicant/#{application.id}")

      assert path == ~p"/companies"
      assert flash["error"] == "You don't have permission to access this company."
    end

    test "renders applicant details page", %{
      conn: conn,
      company: company,
      company_user: company_user,
      job_application: application,
      job: job
    } do
      {:ok, _view, html} =
        conn
        |> log_in_user(company_user)
        |> live(~p"/companies/#{company.id}/applicant/#{application.id}")

      applicant_name = "#{application.user.first_name} #{application.user.last_name}"

      assert html =~ applicant_name
      assert html =~ job.title
      assert html =~ application.cover_letter
    end

    test "displays resume information when available", %{
      conn: conn,
      company: company,
      company_user: company_user,
      job_application: application
    } do
      {:ok, _view, html} =
        conn
        |> log_in_user(company_user)
        |> live(~p"/companies/#{company.id}/applicant/#{application.id}")

      applicant_name = "#{application.user.first_name} #{application.user.last_name}"
      assert html =~ applicant_name
      assert html =~ "View Resume"
    end

    test "allows user to navigate to the applicant chat page", %{
      conn: conn,
      company: company,
      company_user: company_user,
      job_application: application,
      job: job
    } do
      conn = log_in_user(conn, company_user)

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
      company: company,
      company_user: company_user,
      job_application: application
    } do
      conn = log_in_user(conn, company_user)

      assert {:ok, view, _html} =
               live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      assert view
             |> element("a", "Back to Applicants")
             |> has_element?()
    end

    test "displays rating component and allows rating an applicant", %{
      conn: conn,
      company: company,
      company_user: company_user,
      job_application: application
    } do
      conn = log_in_user(conn, company_user)

      {:ok, view, html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      assert html =~ "Rating"
      assert html =~ "Rate"

      view
      |> element("button", "Rate")
      |> render_click()

      assert has_element?(view, "#rating-modal-#{application.id}")
      assert has_element?(view, "h3", "Rate Jane Applicant")

      view
      |> form("#job-seeker-rating-form-#{application.id} form", %{
        "score" => "5",
        "comment" => "Excellent candidate"
      })
      |> render_submit()

      assert render(view) =~ "Rating submitted successfully"

      refute has_element?(view, "#rating-modal-#{application.id}")

      assert render(view) =~ "Update Rating"
      refute render(view) =~ ">Rate<"
    end

    test "updates UI when existing rating is updated", %{
      conn: conn,
      company: company,
      company_user: company_user,
      job_application: application,
      applicant: applicant
    } do
      rating_fixture(%{
        rater_type: "Company",
        rater_id: company.id,
        ratee_type: "User",
        ratee_id: applicant.id,
        score: 3,
        comment: "Good candidate"
      })

      conn = log_in_user(conn, company_user)

      {:ok, view, html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      assert html =~ "Update Rating"
      refute html =~ ">Rate<"

      view
      |> element("button", "Update Rating")
      |> render_click()

      assert has_element?(view, "#rating-modal-#{application.id}")

      view
      |> form("#job-seeker-rating-form-#{application.id} form", %{
        "score" => "5",
        "comment" => "Outstanding candidate"
      })
      |> render_submit()

      assert render(view) =~ "Rating submitted successfully"

      assert render(view) =~ "Update Rating"
      assert render(view) =~ "5.0"
    end

    test "updates ratings in real-time via PubSub", %{
      conn: conn,
      company: company,
      company_user: company_user,
      job_application: application,
      applicant: applicant
    } do
      conn = log_in_user(conn, company_user)

      {:ok, view, _html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      rating =
        rating_fixture(%{
          rater_type: "Company",
          rater_id: company.id,
          ratee_type: "User",
          ratee_id: applicant.id,
          score: 5,
          comment: "Excellent candidate"
        })

      Phoenix.PubSub.broadcast(
        BemedaPersonal.PubSub,
        "rating:User:#{applicant.id}",
        {:rating_created, rating}
      )

      Process.sleep(100)

      html = render(view)
      assert html =~ "star-rating"
      assert html =~ "fill-current"
      assert html =~ "5.0"
    end

    test "closes rating modal when cancel button is clicked", %{
      conn: conn,
      company_user: company_user,
      company: company,
      job_application: application
    } do
      conn = log_in_user(conn, company_user)

      {:ok, view, _html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      view
      |> element("button", "Rate")
      |> render_click()

      assert has_element?(view, "#rating-modal-#{application.id}")

      view
      |> element("button", "Cancel")
      |> render_click()

      refute has_element?(view, "#rating-modal-#{application.id}")
    end
  end
end
