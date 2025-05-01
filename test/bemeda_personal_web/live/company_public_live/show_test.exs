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
      user = user_fixture(confirmed: true)
      company_admin = user_fixture(confirmed: true)
      company = company_fixture(company_admin)
      job_posting = job_posting_fixture(company)

      %{conn: conn, company: company, user: user, job_posting: job_posting}
    end

    test "renders company public profile for unauthenticated users", %{
      company: company,
      conn: conn,
      job_posting: job_posting
    } do
      {:ok, _view, html} = live(conn, ~p"/company/#{company.id}")

      assert html =~ company.name
      assert html =~ company.industry
      assert html =~ company.location
      assert html =~ company.size
      assert html =~ company.website_url
      assert html =~ job_posting.title
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

      assert html =~ company.name
      assert html =~ company.industry
    end

    test "displays correct job count", %{
      company: company,
      conn: conn
    } do
      job_posting_fixture(company)

      {:ok, _view, html} = live(conn, ~p"/company/#{company.id}")

      assert html =~ "Open Positions"
      assert html =~ "2"
    end

    test "allows navigation to all jobs page", %{
      company: company,
      conn: conn
    } do
      {:ok, view, _html} = live(conn, ~p"/company/#{company.id}")

      {:ok, _view, html} =
        view
        |> element("a", "View All Jobs")
        |> render_click()
        |> follow_redirect(conn, ~p"/company/#{company.id}/jobs")

      assert html =~ "Jobs at #{company.name}"
    end

    test "displays rating stars correctly with existing rating", %{
      company: company,
      conn: conn,
      user: user
    } do
      rating_fixture(%{
        ratee_type: "Company",
        ratee_id: company.id,
        rater_type: "User",
        rater_id: user.id,
        score: 4
      })

      {:ok, _view, html} = live(conn, ~p"/company/#{company.id}")

      assert html =~ "Rating"
      assert html =~ "hero-star"
      assert html =~ "4.0"
      assert html =~ "fill-current"
      assert html =~ "text-gray-300"
      assert html =~ "(1)"
    end

    test "displays small-sized rating stars with custom size", %{
      company: company,
      conn: conn,
      user: user
    } do
      rating_fixture(%{
        ratee_type: "Company",
        ratee_id: company.id,
        rater_type: "User",
        rater_id: user.id,
        score: 5
      })

      {:ok, _view, html} = live(conn, ~p"/company/#{company.id}")

      assert html =~ "w-4 h-4"
    end

    test "shows rating form when user clicks rate button", %{
      company: company,
      conn: conn,
      user: user,
      job_posting: job_posting
    } do
      job_application_fixture(user, job_posting)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/#{company.id}")

      assert has_element?(view, "button", "Rate")

      view
      |> element("button", "Rate")
      |> render_click()

      assert has_element?(view, "form")
      assert has_element?(view, "h3", "Rate #{company.name}")
      assert has_element?(view, "label", "Score")
      assert has_element?(view, "label", "Comment")
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
      job_application_fixture(user, job_posting)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/#{company.id}")

      view
      |> element("button", "Rate")
      |> render_click()

      view
      |> form("form", %{
        "score" => "5",
        "comment" => "Great company to work with!"
      })
      |> render_submit()

      assert render(view) =~ "Rating submitted successfully"

      assert %{score: 5, comment: "Great company to work with!"} =
               Ratings.get_rating_by_rater_and_ratee("User", user.id, "Company", company.id)
    end

    test "shows update button for existing ratings", %{
      company: company,
      conn: conn,
      user: user,
      job_posting: job_posting
    } do
      job_application_fixture(user, job_posting)

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

      assert html =~ "Update Rating"
      refute html =~ ">Rate<"

      view
      |> element("button", "Update Rating")
      |> render_click()

      assert has_element?(view, "textarea", "Decent company")

      view
      |> form("form", %{
        "score" => "4",
        "comment" => "Better than I thought initially"
      })
      |> render_submit()

      Process.sleep(100)

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
      job_application_fixture(user, job_posting)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/#{company.id}")

      view
      |> element("button", "Rate")
      |> render_click()

      assert has_element?(view, "form")

      view
      |> element("button", "Cancel")
      |> render_click()

      refute has_element?(view, "form phx-submit")
    end

    test "handles error when user hasn't applied to company job", %{
      company: company,
      conn: conn,
      user: user
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/#{company.id}")

      refute has_element?(view, "button", "Rate")

      render_hook(view, "open-rating-modal", %{
        "entity_id" => company.id,
        "entity_type" => "Company"
      })

      view
      |> with_target("#rating-modal")
      |> render_hook("submit-rating", %{
        "score" => "5",
        "comment" => "Trying to rate without applying"
      })

      assert render(view) =~ "need to apply to a job before rating"
    end

    test "updates UI immediately when rating is submitted", %{
      company: company,
      conn: conn,
      user: user,
      job_posting: job_posting
    } do
      job_application_fixture(user, job_posting)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/#{company.id}")

      view
      |> element("button", "Rate")
      |> render_click()

      view
      |> form("form", %{
        "score" => "5",
        "comment" => "Excellent company!"
      })
      |> render_submit()

      assert render(view) =~ "Rating submitted successfully"

      html = render(view)
      assert html =~ "5.0"

      assert html =~ "Update Rating"
      refute html =~ ">Rate<"
    end

    test "updates UI when another user submits a rating", %{
      company: company,
      conn: conn,
      user: user,
      job_posting: job_posting
    } do
      job_application_fixture(user, job_posting)

      other_user = user_fixture()
      job_application_fixture(other_user, job_posting)

      {:ok, view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/#{company.id}")

      assert html =~ "(0)"

      rating =
        rating_fixture(%{
          rater_type: "User",
          rater_id: other_user.id,
          ratee_type: "Company",
          ratee_id: company.id,
          score: 5,
          comment: "Great company!"
        })

      Phoenix.PubSub.broadcast(
        BemedaPersonal.PubSub,
        "rating:Company:#{company.id}",
        {:rating_created, rating}
      )

      updated_html = render(view)
      assert updated_html =~ "5.0"
      assert updated_html =~ "(1)"
    end
  end
end
