defmodule BemedaPersonalWeb.UserTypeRoutingTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.ResumesFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts.Scope

  describe "job seeker routes access" do
    test "job seekers can access resume routes", %{conn: conn} do
      user = user_fixture(%{user_type: :job_seeker})
      conn = log_in_user(conn, user)

      {:ok, _view, _html} = live(conn, ~p"/resume")
    end

    test "employers are redirected from resume routes to company dashboard", %{conn: conn} do
      user = user_fixture(%{user_type: :employer})
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/company", flash: flash}}} = live(conn, ~p"/resume")
      assert flash["error"] =~ "job seekers only"
    end

    test "job seekers can access job application routes", %{conn: conn} do
      user = user_fixture(%{user_type: :job_seeker})
      conn = log_in_user(conn, user)

      {:ok, _view, _html} = live(conn, ~p"/job_applications")
    end

    test "employers are redirected from job application routes to company dashboard", %{
      conn: conn
    } do
      user = user_fixture(%{user_type: :employer})
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/company", flash: flash}}} =
               live(conn, ~p"/job_applications")

      assert flash["error"] =~ "job seekers only"
    end

    test "unauthenticated users are redirected from job seeker routes to login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log_in", flash: flash}}} = live(conn, ~p"/resume")
      assert flash["error"] =~ "You must log in to access this page"

      assert {:error, {:redirect, %{to: "/users/log_in", flash: flash}}} =
               live(conn, ~p"/job_applications")

      assert flash["error"] =~ "You must log in to access this page"
    end
  end

  describe "employer routes access" do
    test "employers can access company routes", %{conn: conn} do
      user = user_fixture(%{user_type: :employer})
      conn = log_in_user(conn, user)

      {:ok, _view, _html} = live(conn, ~p"/company")
    end

    test "job seekers are redirected from company routes to home page", %{conn: conn} do
      user = user_fixture(%{user_type: :job_seeker})
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/", flash: flash}}} = live(conn, ~p"/company")
      assert flash["error"] =~ "must be an employer"
    end

    test "unauthenticated users are redirected from company routes to login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log_in", flash: flash}}} =
               live(conn, ~p"/company")

      assert flash["error"] =~ "You must log in to access this page"
    end
  end

  describe "shared routes access" do
    test "both user types can access settings", %{conn: conn} do
      job_seeker = user_fixture(%{user_type: :job_seeker})
      employer = user_fixture(%{user_type: :employer})

      conn1 = log_in_user(conn, job_seeker)
      {:ok, _view, _html} = live(conn1, ~p"/users/settings")

      conn2 = log_in_user(conn, employer)
      {:ok, _view, _html} = live(conn2, ~p"/users/settings")
    end

    test "both user types can access notifications", %{conn: conn} do
      job_seeker = user_fixture(%{user_type: :job_seeker})
      employer = user_fixture(%{user_type: :employer})

      conn1 = log_in_user(conn, job_seeker)
      {:ok, _view, _html} = live(conn1, ~p"/notifications")

      conn2 = log_in_user(conn, employer)
      {:ok, _view, _html} = live(conn2, ~p"/notifications")
    end

    test "unauthenticated users are redirected from shared routes to login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log_in", flash: flash}}} =
               live(conn, ~p"/users/settings")

      assert flash["error"] =~ "You must log in to access this page"

      assert {:error, {:redirect, %{to: "/users/log_in", flash: flash}}} =
               live(conn, ~p"/notifications")

      assert flash["error"] =~ "You must log in to access this page"
    end
  end

  describe "public routes access" do
    test "unauthenticated users can access public routes", %{conn: conn} do
      {:ok, _view, _html} = live(conn, ~p"/jobs")
    end

    test "all user types can access public routes", %{conn: conn} do
      job_seeker = user_fixture(%{user_type: :job_seeker})
      employer = user_fixture(%{user_type: :employer})

      conn1 = log_in_user(conn, job_seeker)
      {:ok, _view, _html} = live(conn1, ~p"/jobs")

      conn2 = log_in_user(conn, employer)
      {:ok, _view, _html} = live(conn2, ~p"/jobs")
    end
  end

  describe "user registration and login routes" do
    test "unauthenticated users can access registration and login routes", %{conn: conn} do
      {:ok, _view, _html} = live(conn, ~p"/users/register")
      {:ok, _view, _html} = live(conn, ~p"/users/log_in")
    end

    test "authenticated users are redirected from registration routes", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/users/register")
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/users/log_in")
    end
  end

  describe "company specific routes with user company requirement" do
    test "employer with company can access company-specific routes", %{conn: conn} do
      user = user_fixture(%{user_type: :employer})
      _company = company_fixture(user)
      conn = log_in_user(conn, user)

      {:ok, _view, _html} = live(conn, ~p"/company/jobs")
      {:ok, _view, _html} = live(conn, ~p"/company/applicants")
    end

    test "employer without company is redirected from company-specific routes", %{conn: conn} do
      user = user_fixture(%{user_type: :employer})
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/company/new", flash: flash}}} =
               live(conn, ~p"/company/jobs")

      assert flash["error"] =~ "need to create a company first"

      assert {:error, {:redirect, %{to: "/company/new", flash: flash}}} =
               live(conn, ~p"/company/applicants")

      assert flash["error"] =~ "need to create a company first"
    end
  end

  describe "utility routes" do
    test "users can access public resume route", %{conn: conn} do
      user = user_fixture()
      user_scope = Scope.for_user(user)
      resume = resume_fixture(user_scope)

      {:ok, _view, _html} = live(conn, ~p"/resumes/#{resume.id}")
    end
  end
end
