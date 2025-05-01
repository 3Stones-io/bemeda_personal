defmodule BemedaPersonalWeb.CompanyApplicantLive.ShowTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import BemedaPersonal.RatingsFixtures
  import BemedaPersonal.ResumesFixtures
  import Phoenix.LiveViewTest

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
  end

  describe "applicant rating functionality" do
    test "handles nil average rating", %{
      conn: conn,
      company: company,
      company_user: company_user,
      job_application: application
    } do
      conn = log_in_user(conn, company_user)

      {:ok, _view, html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      assert html =~ "Rating"
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

      {:ok, view, html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      assert html =~ "Rate"

      view
      |> element("button", "Rate")
      |> render_click()

      modal_content = render(view)

      assert modal_content =~ "Rate Jane Applicant"
      assert modal_content =~ "Score"
      assert modal_content =~ "Comment"

      assert modal_content =~ "value=\"3\""

      view
      |> form("#job-seeker-rating-form-#{application.id} form", %{
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

    test "updates when rating is created", %{
      conn: conn,
      company: company,
      company_user: company_user,
      job_application: application,
      applicant: applicant
    } do
      conn = log_in_user(conn, company_user)

      {:ok, view, _html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      rating_fixture(%{
        rater_type: "Company",
        rater_id: company.id,
        ratee_type: "User",
        ratee_id: applicant.id,
        score: 5,
        comment: "Excellent candidate"
      })

      Ratings.create_rating(%{
        rater_type: "Company",
        rater_id: company.id,
        ratee_type: "User",
        ratee_id: applicant.id,
        score: 5,
        comment: "Excellent candidate"
      })

      html = render(view)
      assert html =~ "5.0"
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

    test "handles missing score value", %{
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

      assert has_element?(view, "form")

      view
      |> form("#job-seeker-rating-form-#{application.id} form", %{
        "score" => "4",
        "comment" => "Valid submission"
      })
      |> render_submit()

      assert render(view) =~ "Rating submitted successfully"
    end

    for score <- [1, 5] do
      @tag score: score
      test "tests star rendering with rating #{score}", %{
        conn: conn,
        company: company,
        company_user: company_user,
        job_application: application,
        applicant: applicant,
        score: score
      } do
        rating_fixture(%{
          rater_type: "Company",
          rater_id: company.id,
          ratee_type: "User",
          ratee_id: applicant.id,
          score: score,
          comment: "Rating with score #{score}"
        })

        conn = log_in_user(conn, company_user)
        {:ok, _lv, html} = live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

        assert html =~ "#{score}.0"
      end
    end
  end
end
