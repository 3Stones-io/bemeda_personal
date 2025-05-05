defmodule BemedaPersonalWeb.CompanyApplicantLive.ShowTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import BemedaPersonal.RatingsFixtures
  import BemedaPersonal.ResumesFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Jobs
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

    test "allows updating tags for the application", %{
      company_user: user,
      company: company,
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

      job_application = Jobs.get_job_application!(application.id)
      assert "qualified" in Enum.map(job_application.tags, & &1.name)
      assert "urgent" in Enum.map(job_application.tags, & &1.name)
    end
  end

  describe "applicant ratings" do
    test "displays component with no ratings", %{
      conn: conn,
      company: company,
      company_user: company_user,
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
      conn: conn,
      company: company,
      company_user: company_user,
      job_application: application,
      applicant: applicant
    } do
      rating =
        rating_fixture(%{
          rater_type: "Company",
          rater_id: company.id,
          ratee_type: "User",
          ratee_id: applicant.id,
          score: 4,
          comment: "Good candidate"
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
      conn: conn,
      company: company,
      company_user: company_user,
      job_application: application,
      applicant: applicant
    } do
      other_company = company_fixture(user_fixture(confirmed: true))

      rating1 =
        rating_fixture(%{
          rater_type: "Company",
          rater_id: company.id,
          ratee_type: "User",
          ratee_id: applicant.id,
          score: 3,
          comment: "Average candidate"
        })

      rating2 =
        rating_fixture(%{
          rater_type: "Company",
          rater_id: other_company.id,
          ratee_type: "User",
          ratee_id: applicant.id,
          score: 5,
          comment: "Excellent candidate"
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
      conn: conn,
      company: company,
      company_user: company_user,
      job_application: application,
      applicant: applicant
    } do
      _rating =
        rating_fixture(%{
          rater_type: "Company",
          rater_id: company.id,
          ratee_type: "User",
          ratee_id: applicant.id,
          score: 3,
          comment: "Good candidate"
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
      conn: conn,
      company: company,
      company_user: company_user,
      job_application: application,
      applicant: applicant
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
      conn: conn,
      company: company,
      company_user: company_user,
      job_application: application,
      applicant: applicant
    } do
      conn = log_in_user(conn, company_user)

      {:ok, _view, html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      assert html =~ "(0)"
      assert html =~ "No ratings yet"
      refute html =~ "fill-current"

      rating_fixture(%{
        rater_type: "Company",
        rater_id: company.id,
        ratee_type: "User",
        ratee_id: applicant.id,
        score: 5,
        comment: "Excellent candidate"
      })

      {:ok, _updated_view, updated_html} =
        conn
        |> log_in_user(company_user)
        |> live(~p"/companies/#{company.id}/applicant/#{application.id}")

      assert updated_html =~ "(1)"
      assert updated_html =~ "fill-current"
    end

    test "handles cancel action for rating form", %{
      conn: conn,
      company: company,
      company_user: company_user,
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
      conn: conn,
      company: company,
      company_user: company_user,
      job_application: application,
      applicant: applicant
    } do
      other_company = company_fixture(user_fixture(confirmed: true))

      rating_fixture(%{
        rater_type: "Company",
        rater_id: company.id,
        ratee_type: "User",
        ratee_id: applicant.id,
        score: 3,
        comment: "Average candidate"
      })

      rating_fixture(%{
        rater_type: "Company",
        rater_id: other_company.id,
        ratee_type: "User",
        ratee_id: applicant.id,
        score: 4,
        comment: "Good candidate"
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
