defmodule BemedaPersonalWeb.CompanyPublicLive.ShowTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import BemedaPersonal.RatingsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Ratings

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

      # Verify rating display component is shown (with no ratings yet)
      assert html =~ "Rating"
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

    test "displays rating stars correctly with existing rating", %{
      company: company,
      conn: conn
    } do
      # Create a rating for the company
      rating_fixture(%{
        ratee_type: "Company",
        ratee_id: company.id,
        score: 4
      })

      {:ok, _view, html} = live(conn, ~p"/company/#{company.id}")

      # Verify rating display shows the correct score
      assert html =~ "Rating"
      assert html =~ "hero-star"
      assert html =~ "4.0"

      # 4 filled stars and 1 empty star for rating of 4.0
      assert html =~ "fill-current"
      assert html =~ "text-gray-300"
    end

    test "displays small-sized rating stars with custom size", %{
      company: company,
      conn: conn
    } do
      # Create a rating for the company
      rating_fixture(%{
        ratee_type: "Company",
        ratee_id: company.id,
        score: 5
      })

      {:ok, _view, html} = live(conn, ~p"/company/#{company.id}")

      # Check for small-sized stars (the class comes from size="sm" in the template)
      assert html =~ "w-4 h-4"
    end

    test "shows rating form when user clicks rate button", %{
      company: company,
      conn: conn,
      user: user,
      job_posting: job_posting
    } do
      # Create a job application so user can rate
      job_application_fixture(user, job_posting)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/#{company.id}")

      # First check that the Rate button is shown
      assert has_element?(view, "button", "Rate")

      # Click the Rate button
      view
      |> element("button", "Rate")
      |> render_click()

      # Verify rating form is shown
      assert has_element?(view, "form")
      assert has_element?(view, "h3", "Rate #{company.name}")
      assert has_element?(view, "label", "Score")
      assert has_element?(view, "label", "Comment")

      # Check form elements
      assert has_element?(view, "input[type=radio][name=score][value=1]")
      assert has_element?(view, "input[type=radio][name=score][value=5]")
      assert has_element?(view, "textarea[name=comment]")
      assert has_element?(view, "button", "Submit Rating")
      assert has_element?(view, "button", "Cancel")
    end

    test "can submit rating form successfully", %{
      company: company,
      conn: conn,
      user: user,
      job_posting: job_posting
    } do
      # Create a job application so user can rate
      job_application_fixture(user, job_posting)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/#{company.id}")

      # Open the rating form
      view
      |> element("button", "Rate")
      |> render_click()

      # Submit the form
      view
      |> form("form", %{
        "score" => "5",
        "comment" => "Great company to work with!"
      })
      |> render_submit()

      # Check for success message
      assert render(view) =~ "Rating submitted successfully"

      # Verify the rating was saved in the database
      assert %{score: 5, comment: "Great company to work with!"} =
               Ratings.get_rating_by_rater_and_ratee("User", user.id, "Company", company.id)
    end

    test "shows update button for existing ratings", %{
      company: company,
      conn: conn,
      user: user,
      job_posting: job_posting
    } do
      # Create a job application so user can rate
      job_application_fixture(user, job_posting)

      # User already has a rating
      rating_fixture(%{
        rater_type: "User",
        rater_id: user.id,
        ratee_type: "Company",
        ratee_id: company.id,
        score: 3,
        comment: "Decent company"
      })

      {:ok, view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/#{company.id}")

      # Verify "Update Rating" button is shown instead of "Rate"
      assert html =~ "Update Rating"
      refute html =~ ">Rate<"

      # Click update button
      view
      |> element("button", "Update Rating")
      |> render_click()

      # Check that the form has the existing rating
      assert has_element?(view, "textarea", "Decent company")

      # Update the rating
      view
      |> form("form", %{
        "score" => "4",
        "comment" => "Better than I thought initially"
      })
      |> render_submit()

      # Check updated rating in database
      updated_rating =
        Ratings.get_rating_by_rater_and_ratee("User", user.id, "Company", company.id)

      assert updated_rating.score == 4
      assert updated_rating.comment == "Better than I thought initially"
    end

    test "can close rating form", %{
      company: company,
      conn: conn,
      user: user,
      job_posting: job_posting
    } do
      # Create a job application so user can rate
      job_application_fixture(user, job_posting)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/#{company.id}")

      # Open the rating form
      view
      |> element("button", "Rate")
      |> render_click()

      # Verify form is shown
      assert has_element?(view, "form")

      # Close the form
      view
      |> element("button", "Cancel")
      |> render_click()

      # Verify form is closed
      refute has_element?(view, "form phx-submit")
    end

    test "handles error when user hasn't applied to company job", %{
      company: company,
      conn: conn,
      user: user
    } do
      # User with no job applications
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/#{company.id}")

      # Rate button should not be shown since user hasn't applied
      refute has_element?(view, "button", "Rate")

      # Directly try to open modal (simulating direct event)
      render_hook(view, "open-rating-modal", %{
        "entity_id" => company.id,
        "entity_type" => "Company"
      })

      # Submit a rating (forcing event bypassing UI restrictions)
      view
      |> with_target("#rating-modal")
      |> render_hook("submit-rating", %{
        "score" => "5",
        "comment" => "Trying to rate without applying"
      })

      # Should see error message
      assert render(view) =~ "need to apply to a job before rating"
    end

    test "updates UI immediately when rating is submitted", %{
      company: company,
      conn: conn,
      user: user,
      job_posting: job_posting
    } do
      # Create a job application so user can rate
      job_application_fixture(user, job_posting)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/#{company.id}")

      # Open the rating form
      view
      |> element("button", "Rate")
      |> render_click()

      # Submit a 5-star rating
      view
      |> form("form", %{
        "score" => "5",
        "comment" => "Excellent company!"
      })
      |> render_submit()

      # Check for success message
      assert render(view) =~ "Rating submitted successfully"

      # Verify the UI immediately shows the new rating (without page refresh)
      html = render(view)
      # Check for 5-star rating (5.0 value)
      assert html =~ "5.0"

      # Also should update the "Update Rating" button text
      assert html =~ "Update Rating"
      refute html =~ ">Rate<"
    end

    test "updates UI when another user submits a rating", %{
      company: company,
      conn: conn,
      user: user,
      job_posting: job_posting
    } do
      # Create a job application so user can rate
      job_application_fixture(user, job_posting)

      # Create another user who also applied
      other_user = user_fixture()
      job_application_fixture(other_user, job_posting)

      # First user views the company page
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/#{company.id}")

      # Simulate other_user submitting a rating through PubSub
      # This is equivalent to another user rating the company in a different session
      rating =
        rating_fixture(%{
          rater_type: "User",
          rater_id: other_user.id,
          ratee_type: "Company",
          ratee_id: company.id,
          score: 5,
          comment: "Great company!"
        })

      # Manually send a PubSub message to simulate the rating being created
      Phoenix.PubSub.broadcast(
        BemedaPersonal.PubSub,
        "rating:Company:#{company.id}",
        {:rating_created, rating}
      )

      # Wait a brief moment for the event to be processed
      Process.sleep(100)

      # Verify the view updates to show the new average rating
      # The page should update without refreshing
      html = render(view)

      # The rating display component should update
      assert html =~ "star-rating"
      assert html =~ "fill-current"
    end
  end
end
