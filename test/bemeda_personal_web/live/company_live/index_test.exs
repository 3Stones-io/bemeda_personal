defmodule BemedaPersonalWeb.CompanyLive.IndexTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import BemedaPersonal.RatingsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Ratings

  describe "Company Dashboard" do
    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/companies")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "renders company dashboard when user has a company", %{conn: conn} do
      user = user_fixture()
      company = company_fixture(user)

      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies")

      assert html =~ company.name
      assert html =~ company.industry
      assert html =~ "Company Dashboard"
      assert html =~ "Edit Company Profile"

      assert html =~ company.location
      assert html =~ company.size

      assert html =~ company.website_url
      assert html =~ "hero-star"
    end

    test "shows job count correctly", %{conn: conn} do
      company_admin = user_fixture(confirmed: true)
      company = company_fixture(company_admin)
      job_posting_fixture(company)
      job_posting_fixture(company)

      {:ok, _view, html} =
        conn
        |> log_in_user(company_admin)
        |> live(~p"/companies")

      assert html =~ "Open Positions"
      assert html =~ "2"
    end

    test "users can edit their company", %{conn: conn} do
      company_admin = user_fixture(confirmed: true)
      company = company_fixture(company_admin)

      {:ok, view, _html} =
        conn
        |> log_in_user(company_admin)
        |> live(~p"/companies")

      assert view
             |> element("a[href='/companies/#{company.id}/edit']")
             |> has_element?()
    end

    test "users can navigate to view all jobs", %{conn: conn} do
      user = user_fixture()
      company = company_fixture(user)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies")

      assert view
             |> element("a[href='/companies/#{company.id}/jobs']")
             |> has_element?()
    end

    test "users can navigate to create a company if they don't have one", %{conn: conn} do
      user = user_fixture()

      {:ok, view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies")

      assert html =~ "Create Your Company Profile"
      assert html =~ "You need to create a company profile before you can post jobs"

      assert view
             |> element("a[href='/companies/new']")
             |> has_element?()
    end
  end

  describe "company ratings" do
    setup %{conn: conn} do
      company_admin = user_fixture(confirmed: true)
      company = company_fixture(company_admin)
      user = user_fixture(confirmed: true)

      %{
        company: company,
        company_admin: company_admin,
        conn: log_in_user(conn, company_admin),
        user: user
      }
    end

    test "displays component with no ratings", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/companies")

      assert html =~ "hero-star"
      assert html =~ "text-gray-300"
      refute html =~ "fill-current"
      assert html =~ "(0)"
      assert html =~ "No ratings yet"

      refute has_element?(view, "button", "Rate")
      refute has_element?(view, "button", "Update Rating")
    end

    test "displays component with one rating", %{
      company: company,
      conn: conn,
      user: user
    } do
      rating_fixture(%{
        ratee_id: company.id,
        ratee_type: "Company",
        rater_id: user.id,
        rater_type: "User",
        score: 4
      })

      {:ok, _view, html} = live(conn, ~p"/companies")

      assert html =~ "4.0"
      assert html =~ "(1)"
      assert html =~ "fill-current"
      assert html =~ "text-gray-300"
    end

    test "displays partial rating correctly with decimal value", %{
      company: company,
      conn: conn
    } do
      user1 = user_fixture(confirmed: true)
      user2 = user_fixture(confirmed: true)

      rating_fixture(%{
        ratee_id: company.id,
        ratee_type: "Company",
        rater_id: user1.id,
        rater_type: "User",
        score: 3
      })

      rating_fixture(%{
        ratee_id: company.id,
        ratee_type: "Company",
        rater_id: user2.id,
        rater_type: "User",
        score: 4
      })

      {:ok, _view, html} = live(conn, ~p"/companies")

      assert html =~ "3.5"
      assert html =~ "(2)"
      assert html =~ "fill-current"
    end

    test "rating display updates in real-time when ratings change", %{
      company: company,
      conn: conn
    } do
      user = user_fixture(confirmed: true)
      job_posting = job_posting_fixture(company)
      job_application_fixture(user, job_posting)

      {:ok, view, html} = live(conn, ~p"/companies")

      assert html =~ "(0)"
      assert html =~ "No ratings yet"
      refute html =~ "fill-current"

      Ratings.rate_company(user, company, %{
        comment: "Excellent company!",
        score: 5
      })

      # Flaky test, sometimes the rating is not updated in time
      Process.sleep(100)

      updated_html = render(view)
      assert updated_html =~ "5.0"
      assert updated_html =~ "(1)"
      assert updated_html =~ "fill-current"
    end
  end

  describe "Create Company" do
    test "redirects if user is already has a company", %{conn: conn} do
      user = user_fixture()
      _company = company_fixture(user)

      assert {:error, {:redirect, %{to: path}}} =
               conn
               |> log_in_user(user)
               |> live(~p"/companies/new")

      assert path == ~p"/companies"
    end

    test "renders company creation form", %{conn: conn} do
      user = user_fixture()

      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/new")

      assert html =~ "Create Company Profile"
      assert html =~ "Company Name"
      assert html =~ "Industry"
      assert html =~ "Company Description"
    end

    test "allows a user to create a company", %{conn: conn} do
      user = user_fixture()

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/new")

      _result =
        view
        |> form("#company-form", %{
          "company" => %{
            "name" => "Test Company",
            "industry" => "Technology",
            "description" => "A test company description",
            "location" => "Test Location",
            "size" => "Small",
            "website_url" => "https://example.com"
          }
        })
        |> render_submit()

      assert_redirect(view, ~p"/companies")

      assert Companies.get_company_by_user(user)
    end

    test "shows validation errors", %{conn: conn} do
      user = user_fixture()

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/new")

      _result =
        view
        |> form("#company-form", %{
          "company" => %{
            "name" => "",
            "industry" => "Technology"
          }
        })
        |> render_submit()

      assert render(view) =~ "can&#39;t be blank"
    end

    test "shows error with invalid data", %{conn: conn} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/companies/new")

      assert render_submit(form(view, "#company-form", company: %{name: nil})) =~
               "can&#39;t be blank"
    end
  end

  describe "Edit Company" do
    test "redirects if user is not admin of the company", %{conn: conn} do
      user = user_fixture()
      other_user = user_fixture(%{email: "other@example.com"})
      company = company_fixture(user)

      assert {:error, {:redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(other_user)
               |> live(~p"/companies/#{company.id}/edit")

      assert path == ~p"/companies"
      assert flash["error"] == "You don't have permission to access this company."
    end

    test "allows admin to edit company", %{conn: conn} do
      user = user_fixture()
      company = company_fixture(user)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/edit")

      _result =
        view
        |> form("#company-form", %{
          "company" => %{
            "name" => "Updated Company Name",
            "industry" => company.industry
          }
        })
        |> render_submit()

      assert_redirect(view, ~p"/companies")

      updated_company = Companies.get_company!(company.id)
      assert updated_company.name == "Updated Company Name"
    end
  end

  describe "Job Management" do
    test "allows creating a new job posting", %{conn: conn} do
      user = user_fixture()
      company = company_fixture(user)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/jobs/new")

      assert has_element?(view, "form[phx-submit='save']")
    end

    test "updates applicants list when someone applies for the job", %{conn: conn} do
      company_user = user_fixture()
      company = company_fixture(company_user)
      job_posting = job_posting_fixture(company)

      job_applicant =
        user_fixture(%{first_name: "New", last_name: "Applicant", email: "new@example.com"})

      {:ok, view, _html} =
        conn
        |> log_in_user(company_user)
        |> live(~p"/companies")

      {:ok, _new_application} =
        Jobs.create_job_application(job_applicant, job_posting, %{
          cover_letter: "I am very interested in this position"
        })

      Process.sleep(50)

      updated_html = render(view)
      assert updated_html =~ "New Applicant"
      assert updated_html =~ "new@example.com"
    end
  end
end
