defmodule BemedaPersonalWeb.CompanyApplicantLive.ShowTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import BemedaPersonal.RatingsFixtures
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

    test "displays rating component and allows rating an applicant", %{
      conn: conn,
      company_user: user,
      company: company,
      job_application: application
    } do
      conn = log_in_user(conn, user)

      {:ok, view, html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      # Check that rating component is displayed
      assert html =~ "Rating"
      assert html =~ "Rate"

      # Click the Rate button
      view
      |> element("button", "Rate")
      |> render_click()

      # Verify the rating modal is shown
      assert has_element?(view, "#rating-modal-#{application.id}")
      assert has_element?(view, "h3", "Rate Jane Applicant")

      # Submit a rating
      view
      |> form("#job-seeker-rating-form-#{application.id} form", %{
        "score" => "5",
        "comment" => "Excellent candidate"
      })
      |> render_submit()

      # Check for success message
      assert render(view) =~ "Rating submitted successfully"

      # Verify the modal is closed
      refute has_element?(view, "#rating-modal-#{application.id}")

      # Verify the rating is now shown (button should show "Update Rating" instead of "Rate")
      assert render(view) =~ "Update Rating"
      refute render(view) =~ ">Rate<"
    end

    test "updates UI when existing rating is updated", %{
      conn: conn,
      company_user: user,
      company: company,
      job_application: application,
      applicant: applicant
    } do
      # Create an initial rating
      rating_fixture(%{
        rater_type: "User",
        rater_id: user.id,
        ratee_type: "User",
        ratee_id: applicant.id,
        score: 3,
        comment: "Good candidate"
      })

      conn = log_in_user(conn, user)

      {:ok, view, html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      # Verify initial rating state - should show "Update Rating" instead of "Rate"
      assert html =~ "Update Rating"
      refute html =~ ">Rate<"

      # Click the Update Rating button
      view
      |> element("button", "Update Rating")
      |> render_click()

      # Verify the rating modal is shown with existing rating
      assert has_element?(view, "#rating-modal-#{application.id}")

      # Submit an updated rating
      view
      |> form("#job-seeker-rating-form-#{application.id} form", %{
        "score" => "5",
        "comment" => "Outstanding candidate"
      })
      |> render_submit()

      # Check for success message
      assert render(view) =~ "Rating submitted successfully"

      # Verify the rating is updated
      assert render(view) =~ "Update Rating"
      assert render(view) =~ "5.0"
    end

    test "updates ratings in real-time via PubSub", %{
      conn: conn,
      company_user: user,
      company: company,
      job_application: application,
      applicant: applicant
    } do
      conn = log_in_user(conn, user)

      {:ok, view, _html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      # Create another user
      other_user = user_fixture()

      # Simulate other_user submitting a rating through PubSub
      rating =
        rating_fixture(%{
          rater_type: "User",
          rater_id: other_user.id,
          ratee_type: "User",
          ratee_id: applicant.id,
          score: 5,
          comment: "Excellent candidate"
        })

      # Manually send a PubSub message to simulate the rating being created
      Phoenix.PubSub.broadcast(
        BemedaPersonal.PubSub,
        "rating:User:#{applicant.id}",
        {:rating_created, rating}
      )

      # Wait a brief moment for the event to be processed
      Process.sleep(100)

      # The page should update without refreshing
      html = render(view)

      # The rating display component should update
      assert html =~ "star-rating"
      assert html =~ "fill-current"
      assert html =~ "5.0"
    end

    test "closes rating modal when cancel button is clicked", %{
      conn: conn,
      company_user: user,
      company: company,
      job_application: application
    } do
      conn = log_in_user(conn, user)

      {:ok, view, _html} =
        live(conn, ~p"/companies/#{company.id}/applicant/#{application.id}")

      # Click the Rate button to open modal
      view
      |> element("button", "Rate")
      |> render_click()

      # Verify modal is shown
      assert has_element?(view, "#rating-modal-#{application.id}")

      # Click cancel button
      view
      |> element("button", "Cancel")
      |> render_click()

      # Verify modal is closed
      refute has_element?(view, "#rating-modal-#{application.id}")
    end
  end
end
