defmodule BemedaPersonalWeb.CompanyPublicLive.ShowTest do
  use BemedaPersonalWeb.ConnCase, async: false

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures
  import BemedaPersonal.RatingsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Ratings

  describe "Show" do
    setup %{conn: conn} do
      user = user_fixture(confirmed: true)
      company_admin = employer_user_fixture(confirmed: true)
      company = company_fixture(company_admin)
      job_posting = job_posting_fixture(company)

      %{company: company, conn: conn, job_posting: job_posting, user: user}
    end

    test "renders company public profile for unauthenticated users", %{
      company: company,
      conn: conn,
      job_posting: job_posting
    } do
      {:ok, _view, html} = live(conn, ~p"/companies/#{company.id}")

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
        |> live(~p"/companies/#{company.id}")

      assert html =~ company.name
      assert html =~ company.industry
    end

    test "displays correct job count", %{
      company: company,
      conn: conn
    } do
      job_posting_fixture(company)

      {:ok, _view, html} = live(conn, ~p"/companies/#{company.id}")

      assert html =~ "Open Positions"
      assert html =~ "2"
    end

    test "allows navigation to all jobs page", %{
      company: company,
      conn: conn
    } do
      {:ok, view, _html} = live(conn, ~p"/companies/#{company.id}")

      {:ok, _view, html} =
        view
        |> element("a", "View All Jobs")
        |> render_click()
        |> follow_redirect(conn, ~p"/companies/#{company.id}/jobs")

      assert html =~ "Jobs at #{company.name}"
    end
  end

  describe "company ratings" do
    setup %{conn: conn} do
      user = user_fixture(confirmed: true)
      company_admin = employer_user_fixture(confirmed: true)
      company = company_fixture(company_admin)
      job_posting = job_posting_fixture(company)

      %{company: company, conn: conn, job_posting: job_posting, user: user}
    end

    test "displays component with no ratings", %{
      company: company,
      conn: conn
    } do
      {:ok, _view, html} = live(conn, ~p"/companies/#{company.id}")

      assert html =~ "Rating"
      assert html =~ "hero-star"
      assert html =~ "No ratings yet"
      refute html =~ "fill-current"
      assert html =~ "(0)"
    end

    test "displays correct rating with single rating", %{
      company: company,
      conn: conn,
      user: user
    } do
      rating_fixture(%{
        comment: "Good company",
        ratee_id: company.id,
        ratee_type: "Company",
        rater_id: user.id,
        rater_type: "User",
        score: 4
      })

      {:ok, _view, html} = live(conn, ~p"/companies/#{company.id}")

      assert html =~ "Rating"
      assert html =~ "hero-star"
      assert html =~ "4.0"
      assert html =~ "fill-current"
      assert html =~ "(1)"
    end

    test "displays average of multiple ratings correctly", %{
      company: company,
      conn: conn
    } do
      user1 = user_fixture(confirmed: true)
      user2 = user_fixture(confirmed: true)

      rating_fixture(%{
        comment: "Average company",
        ratee_id: company.id,
        ratee_type: "Company",
        rater_id: user1.id,
        rater_type: "User",
        score: 3
      })

      rating_fixture(%{
        comment: "Great company",
        ratee_id: company.id,
        ratee_type: "Company",
        rater_id: user2.id,
        rater_type: "User",
        score: 5
      })

      {:ok, _view, html} = live(conn, ~p"/companies/#{company.id}")

      assert html =~ "Rating"
      assert html =~ "4.0"
      assert html =~ "(2)"
      assert html =~ "fill-current"
    end

    test "user who hasn't applied to company job doesn't see 'Rate' button", %{
      company: company,
      conn: conn,
      user: user
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}")

      refute has_element?(view, "#rating-component-header-#{company.id} button", "Rate")
    end

    test "user who has applied sees 'Rate' button", %{
      company: company,
      conn: conn,
      job_posting: job_posting,
      user: user
    } do
      job_application_fixture(user, job_posting)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}")

      assert has_element?(view, "#rating-component-header-#{company.id} button", "Rate")
    end

    test "user who has already rated sees 'Update Rating' button", %{
      company: company,
      conn: conn,
      job_posting: job_posting,
      user: user
    } do
      job_application_fixture(user, job_posting)

      rating_fixture(%{
        comment: "Good company",
        ratee_id: company.id,
        ratee_type: "Company",
        rater_id: user.id,
        rater_type: "User",
        score: 4
      })

      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}")

      assert html =~ "Update Rating"
      refute html =~ ">Rate<"
    end

    test "rating modal opens when user clicks 'Rate' button", %{
      company: company,
      conn: conn,
      job_posting: job_posting,
      user: user
    } do
      job_application_fixture(user, job_posting)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}")

      view
      |> element("#rating-component-header-#{company.id} button", "Rate")
      |> render_click()

      assert has_element?(view, "form")
      assert has_element?(view, "h3", "Rate #{company.name}")
      assert has_element?(view, "label", "Score")
      assert has_element?(view, "input[name=\"score\"][value=\"5\"]")
    end

    test "user submits valid rating and sees success message", %{
      company: company,
      conn: conn,
      job_posting: job_posting,
      user: user
    } do
      job_application_fixture(user, job_posting)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}")

      view
      |> element("#rating-component-header-#{company.id} button", "Rate")
      |> render_click()

      view
      |> form("form", %{
        "score" => "5",
        "comment" => "Excellent company to work with!"
      })
      |> render_submit()

      html = render(view)
      assert html =~ "Rating submitted successfully"
      assert html =~ "5.0"
      assert html =~ "(1)"
      assert html =~ "fill-current"
    end

    test "user updates existing rating and UI immediately reflects change", %{
      company: company,
      conn: conn,
      job_posting: job_posting,
      user: user
    } do
      job_application_fixture(user, job_posting)

      rating_fixture(%{
        comment: "Average company",
        ratee_id: company.id,
        ratee_type: "Company",
        rater_id: user.id,
        rater_type: "User",
        score: 3
      })

      {:ok, view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}")

      assert html =~ "3.0"
      assert html =~ "(1)"

      view
      |> element("#rating-component-header-#{company.id} button", "Update Rating")
      |> render_click()

      view
      |> form("form", %{
        "score" => "5",
        "comment" => "Much better than I initially thought!"
      })
      |> render_submit()

      # Flaky test, sometimes the rating is not updated in time
      Process.sleep(100)

      updated_html = render(view)
      assert updated_html =~ "Rating submitted successfully"
      assert updated_html =~ "5.0"
      assert updated_html =~ "(1)"
    end

    test "rating display updates in real-time when ratings change", %{
      company: company,
      conn: conn,
      job_posting: job_posting,
      user: user
    } do
      job_application_fixture(user, job_posting)

      {:ok, view, html} = live(conn, ~p"/companies/#{company}")

      assert html =~ "No ratings yet"
      refute html =~ "fill-current"
      assert html =~ "(0)"

      Ratings.rate_company(user, company, %{comment: "Great company!", score: 5})

      # Flaky test, sometimes the rating is not updated in time
      Process.sleep(100)

      updated_html = render(view)
      assert updated_html =~ "5.0"
      assert updated_html =~ "(1)"
      assert updated_html =~ "fill-current"
    end

    test "sidebar rating component syncs with header component", %{
      company: company,
      conn: conn,
      user: user
    } do
      rating_fixture(%{
        comment: "Good company",
        ratee_id: company.id,
        ratee_type: "Company",
        rater_id: user.id,
        rater_type: "User",
        score: 4
      })

      {:ok, view, _html} = live(conn, ~p"/companies/#{company.id}")

      header_rating =
        view
        |> element("#rating-component-header-#{company.id}")
        |> render()

      sidebar_rating =
        view
        |> element("#rating-component-sidebar-#{company.id}")
        |> render()

      assert header_rating =~ "4.0"
      assert sidebar_rating =~ "4.0"

      assert header_rating =~ "(1)"
      assert sidebar_rating =~ "(1)"
    end

    test "both rating components update simultaneously when rating changes", %{
      company: company,
      conn: conn,
      job_posting: job_posting,
      user: user
    } do
      job_application_fixture(user, job_posting)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}")

      header_before =
        view
        |> element("#rating-component-header-#{company.id}")
        |> render()

      sidebar_before =
        view
        |> element("#rating-component-sidebar-#{company.id}")
        |> render()

      assert header_before =~ "(0)"
      assert sidebar_before =~ "(0)"

      view
      |> element("#rating-component-header-#{company.id} button", "Rate")
      |> render_click()

      view
      |> form("form", %{
        "score" => "5",
        "comment" => "Excellent company!"
      })
      |> render_submit()

      header_after =
        view
        |> element("#rating-component-header-#{company.id}")
        |> render()

      sidebar_after =
        view
        |> element("#rating-component-sidebar-#{company.id}")
        |> render()

      assert header_after =~ "5.0"
      assert sidebar_after =~ "5.0"
      assert header_after =~ "(1)"
      assert sidebar_after =~ "(1)"
    end

    test "cancelling rating form closes modal without submitting", %{
      company: company,
      conn: conn,
      job_posting: job_posting,
      user: user
    } do
      job_application_fixture(user, job_posting)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}")

      view
      |> element("#rating-component-header-#{company.id} button", "Rate")
      |> render_click()

      assert has_element?(view, "form")

      view
      |> element("button", "Cancel")
      |> render_click()

      refute has_element?(view, "h3", "Rate #{company.name}")
    end
  end
end
