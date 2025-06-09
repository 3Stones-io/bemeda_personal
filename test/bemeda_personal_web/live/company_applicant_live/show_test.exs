defmodule BemedaPersonalWeb.CompanyApplicantLive.ShowTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures
  import BemedaPersonal.RatingsFixtures
  import BemedaPersonal.ResumesFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.Ratings

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
      applicant: applicant_user,
      company: company,
      company_user: company_user,
      conn: conn,
      job: job,
      job_application: job_application,
      resume: resume
    }
  end

  describe "/companies/:company_id/applicant/:id" do
    test "redirects if user is not logged in", %{
      company: company,
      conn: conn,
      job_application: application
    } do
      assert {:error, redirect} =
               live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "redirects if user is not admin of the company", %{
      company: company,
      conn: conn,
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
      company: company,
      company_user: company_user,
      conn: conn,
      job: job,
      job_application: application
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
      company: company,
      company_user: company_user,
      conn: conn,
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
      company: company,
      company_user: company_user,
      conn: conn,
      job: job,
      job_application: application
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
      company: company,
      company_user: company_user,
      conn: conn,
      job_application: application
    } do
      conn = log_in_user(conn, company_user)

      assert {:ok, view, _html} =
               live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      assert view
             |> element("a", "Back to Applicants")
             |> has_element?()
    end

    test "allows updating tags for the application", %{
      company: company,
      company_user: user,
      conn: conn,
      job_application: application
    } do
      conn = log_in_user(conn, user)

      {:ok, view, _html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      assert has_element?(view, "#tags-input")

      view
      |> element("#tags-input")
      |> render_hook("update_tags", %{tags: "qualified,urgent"})

      job_application = JobApplications.get_job_application!(application.id)
      assert "qualified" in Enum.map(job_application.tags, & &1.name)
      assert "urgent" in Enum.map(job_application.tags, & &1.name)
    end
  end

  describe "applicant ratings" do
    test "displays component with no ratings", %{
      company: company,
      company_user: company_user,
      conn: conn,
      job_application: application
    } do
      conn = log_in_user(conn, company_user)

      {:ok, _view, html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      assert html =~ "Rating"
      assert html =~ "hero-star"
      refute html =~ "fill-current"
      assert html =~ "(0)"
    end

    test "displays component with one rating", %{
      applicant: applicant,
      company: company,
      company_user: company_user,
      conn: conn,
      job_application: application
    } do
      rating =
        rating_fixture(%{
          comment: "Good candidate",
          ratee_id: applicant.id,
          ratee_type: "User",
          rater_id: company.id,
          rater_type: "Company",
          score: 4
        })

      conn = log_in_user(conn, company_user)

      {:ok, _view, html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      assert html =~ "Rating"
      assert html =~ "4.0"
      assert html =~ "(1)"
      assert html =~ "fill-current"
      assert rating.score == 4
    end

    test "displays component with multiple ratings", %{
      applicant: applicant,
      company: company,
      company_user: company_user,
      conn: conn,
      job_application: application
    } do
      other_company = company_fixture(user_fixture(confirmed: true))

      rating1 =
        rating_fixture(%{
          comment: "Average candidate",
          ratee_id: applicant.id,
          ratee_type: "User",
          rater_id: company.id,
          rater_type: "Company",
          score: 3
        })

      rating2 =
        rating_fixture(%{
          comment: "Excellent candidate",
          ratee_id: applicant.id,
          ratee_type: "User",
          rater_id: other_company.id,
          rater_type: "Company",
          score: 5
        })

      conn = log_in_user(conn, company_user)

      {:ok, _view, html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      assert html =~ "Rating"
      assert html =~ "4.0"
      assert html =~ "(2)"
      assert html =~ "fill-current"
      assert rating1.score == 3
      assert rating2.score == 5
    end

    test "rating form prefills with existing rating", %{
      applicant: applicant,
      company: company,
      company_user: company_user,
      conn: conn,
      job_application: application
    } do
      _rating =
        rating_fixture(%{
          comment: "Good candidate",
          ratee_id: applicant.id,
          ratee_type: "User",
          rater_id: company.id,
          rater_type: "Company",
          score: 3
        })

      conn = log_in_user(conn, company_user)

      {:ok, view, _html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      html =
        view
        |> element("button", "Update Rating")
        |> render_click()

      assert html =~ "Rate Jane Applicant"
      assert html =~ "Good candidate"
      assert html =~ "value=\"3\" checked"

      view
      |> form("#rating-form-#{applicant.id} form", %{
        "score" => "4",
        "comment" => "Updated comment"
      })
      |> render_submit()

      assert render(view) =~ "Rating submitted successfully"

      updated_rating =
        Ratings.get_rating_by_rater_and_ratee(
          "Company",
          company.id,
          "User",
          applicant.id
        )

      assert updated_rating.score == 4
      assert updated_rating.comment == "Updated comment"
    end

    test "submits new rating successfully", %{
      applicant: applicant,
      company: company,
      company_user: company_user,
      conn: conn,
      job_application: application
    } do
      conn = log_in_user(conn, company_user)

      {:ok, view, _html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      view
      |> element("button", "Rate")
      |> render_click()

      view
      |> form("#rating-form-#{applicant.id} form", %{
        "score" => "5",
        "comment" => "Excellent applicant"
      })
      |> render_submit()

      assert render(view) =~ "Rating submitted successfully"

      rating =
        Ratings.get_rating_by_rater_and_ratee(
          "Company",
          company.id,
          "User",
          applicant.id
        )

      assert rating.score == 5
      assert rating.comment == "Excellent applicant"
    end

    test "rating display updates in real-time when ratings change", %{
      applicant: applicant,
      company: company,
      company_user: company_user,
      conn: conn,
      job_application: application
    } do
      conn = log_in_user(conn, company_user)

      {:ok, view, html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      assert html =~ "(0)"
      assert html =~ "No ratings yet"
      refute html =~ "fill-current"

      Ratings.rate_user(company, applicant, %{
        comment: "Excellent candidate",
        score: 5
      })

      # Flaky test, sometimes the rating is not updated in time
      Process.sleep(100)

      updated_html = render(view)
      assert updated_html =~ "5.0"
      assert updated_html =~ "(1)"
      assert updated_html =~ "fill-current"
    end

    test "handles cancel action for rating form", %{
      company: company,
      company_user: company_user,
      conn: conn,
      job_application: application
    } do
      conn = log_in_user(conn, company_user)

      {:ok, view, _html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      view
      |> element("button", "Rate")
      |> render_click()

      assert has_element?(view, "h3", "Rate Jane Applicant")

      view
      |> element("button", "Cancel")
      |> render_click()

      refute has_element?(view, "h3", "Rate Jane Applicant")
    end

    test "renders decimal ratings correctly", %{
      applicant: applicant,
      company: company,
      company_user: company_user,
      conn: conn,
      job_application: application
    } do
      other_company = company_fixture(user_fixture(confirmed: true))

      rating_fixture(%{
        comment: "Average candidate",
        ratee_id: applicant.id,
        ratee_type: "User",
        rater_id: company.id,
        rater_type: "Company",
        score: 3
      })

      rating_fixture(%{
        comment: "Good candidate",
        ratee_id: applicant.id,
        ratee_type: "User",
        rater_id: other_company.id,
        rater_type: "Company",
        score: 4
      })

      {:ok, _view, html} =
        conn
        |> log_in_user(company_user)
        |> live(~p"/companies/#{company.id}/applicant/#{application.id}")

      assert html =~ "Rating"
      assert html =~ "3.5"
      assert html =~ "(2)"
      assert html =~ "fill-current"
    end
  end
end
