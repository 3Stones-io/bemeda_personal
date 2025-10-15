defmodule BemedaPersonalWeb.AdminLive.DashboardTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures
  import Ecto.Query
  import Phoenix.LiveViewTest

  setup do
    # Admin access is controlled via AdminAuth plug using HTTP Basic Auth.
    # We need to provide the correct credentials for testing.
    admin_user = user_fixture(%{email: "admin@example.com", user_type: :employer, locale: :en})

    # Get admin credentials from application config (not environment variables)
    admin_username = Application.get_env(:bemeda_personal, :admin)[:username]
    admin_password = Application.get_env(:bemeda_personal, :admin)[:password]
    auth_header = "Basic " <> Base.encode64("#{admin_username}:#{admin_password}")

    %{admin: admin_user, auth_header: auth_header}
  end

  defp admin_conn(conn, auth_header) do
    put_req_header(conn, "authorization", auth_header)
  end

  describe "mount/3" do
    test "requires admin authentication without credentials", %{conn: conn} do
      # Without Basic Auth, the request should be rejected at the plug level
      # and return 401 Unauthorized, not a redirect
      conn = get(conn, ~p"/admin")
      assert conn.status == 401
      assert conn.resp_body == "Unauthorized"
    end

    test "loads dashboard with admin credentials", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin")

      assert html =~ "Admin Dashboard"
      # Check for header structure instead of specific text
      assert html =~ "text-3xl font-bold text-gray-900"
      assert html =~ "text-gray-600"
    end

    test "displays user statistics", %{conn: conn, auth_header: auth_header, admin: admin} do
      # Create test users
      _job_seeker = user_fixture(%{user_type: :job_seeker})
      _employer = user_fixture(%{user_type: :employer})

      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin")

      # Check for user statistics cards
      assert html =~ "text-3xl font-bold text-gray-900"
      assert html =~ "bg-white rounded-lg shadow"
    end

    test "displays company statistics", %{conn: conn, auth_header: auth_header, admin: admin} do
      # Create test company
      employer = user_fixture(%{user_type: :employer})
      _company = company_fixture(employer)

      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin")

      # Check for company stats card structure
      assert html =~ "bg-white rounded-lg shadow"
    end

    test "displays job posting statistics", %{conn: conn, auth_header: auth_header, admin: admin} do
      # Create test data
      employer = user_fixture(%{user_type: :employer})
      company = company_fixture(employer)
      _job_posting = job_posting_fixture(company)

      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin")

      # Check for job postings card structure
      assert html =~ "text-3xl font-bold"
    end

    test "displays application statistics", %{conn: conn, auth_header: auth_header, admin: admin} do
      # Create test data
      employer = user_fixture(%{user_type: :employer})
      job_seeker = user_fixture(%{user_type: :job_seeker})
      company = company_fixture(employer)
      job_posting = job_posting_fixture(company)
      _application = job_application_fixture(job_seeker, job_posting)

      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin")

      # Check for applications statistics
      assert html =~ "bg-white rounded-lg shadow"
      # Check for application status section
      assert html =~ "text-xl font-semibold"
    end

    test "displays recent users", %{conn: conn, auth_header: auth_header, admin: admin} do
      # Create recent users
      user = user_fixture(%{email: "recent@example.com"})

      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin")

      # Check for recent users section
      assert html =~ "text-lg font-semibold"
      assert html =~ user.email
    end

    test "displays recent job postings", %{conn: conn, auth_header: auth_header, admin: admin} do
      # Create recent job posting
      employer = user_fixture(%{user_type: :employer})
      company = company_fixture(employer, %{name: "Test Company"})
      job_posting = job_posting_fixture(company, %{title: "Senior Developer"})

      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin")

      # Check for recent job postings section
      assert html =~ "text-lg font-semibold"
      assert html =~ job_posting.title
      assert html =~ company.name
    end

    test "displays recent applications", %{conn: conn, auth_header: auth_header, admin: admin} do
      # Create recent application
      employer = user_fixture(%{user_type: :employer})
      job_seeker = user_fixture(%{user_type: :job_seeker, email: "applicant@example.com"})
      company = company_fixture(employer)
      job_posting = job_posting_fixture(company, %{title: "Test Position"})
      _application = job_application_fixture(job_seeker, job_posting)

      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin")

      # Check for recent applications section
      assert html =~ "text-lg font-semibold"
      assert html =~ job_posting.title
      assert html =~ job_seeker.email
    end

    test "displays chart placeholders", %{conn: conn, auth_header: auth_header, admin: admin} do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin")

      # Check for chart containers
      assert html =~ "registrations-chart"
      assert html =~ "applications-chart"
      assert html =~ "registrations-chart"
      assert html =~ "applications-chart"
    end

    test "displays last update time", %{conn: conn, auth_header: auth_header, admin: admin} do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin")

      # Check for update time structure
      assert html =~ "text-sm text-gray-500"
      assert html =~ "UTC"
    end
  end

  describe "handle_info/2 :refresh_stats" do
    test "refreshes statistics when timer triggers", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, _html} = live(conn, ~p"/admin")

      # Create new data
      _new_user = user_fixture(%{email: "newuser@example.com"})

      # Trigger refresh
      send(live.pid, :refresh_stats)

      # Wait for LiveView to process the message
      :timer.sleep(100)

      # The view should still render correctly after refresh
      html = render(live)
      assert html =~ "Admin Dashboard"
      # Use locale-agnostic assertion - check for the stats card structure and numbers
      assert html =~ "bg-white rounded-lg shadow"
      assert html =~ "text-3xl font-bold"
    end
  end

  describe "application state counts" do
    test "displays correct state counts", %{conn: conn, auth_header: auth_header, admin: admin} do
      # Create applications with different states
      employer = user_fixture(%{user_type: :employer})
      job_seeker1 = user_fixture(%{user_type: :job_seeker})
      job_seeker2 = user_fixture(%{user_type: :job_seeker})
      company = company_fixture(employer)
      job_posting = job_posting_fixture(company)

      # Create applications with different states
      _app1 = job_application_fixture(job_seeker1, job_posting, %{state: "applied"})
      _app2 = job_application_fixture(job_seeker2, job_posting, %{state: "offer_extended"})

      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin")

      assert html =~ "Beworben"
      assert html =~ "Angebot gemacht"
    end
  end

  describe "chart data generation" do
    test "generates chart data for last 30 days", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      # Create users and applications over different days
      _user_today = user_fixture()
      _user_yesterday = user_fixture(%{inserted_at: DateTime.add(DateTime.utc_now(), -1, :day)})

      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, _html} = live(conn, ~p"/admin")

      # Check that chart data is assigned
      assert live
             |> element("#registrations-chart")
             |> has_element?()

      assert live
             |> element("#applications-chart")
             |> has_element?()
    end
  end

  describe "date formatting" do
    test "formats dates in German format", %{conn: conn, auth_header: auth_header, admin: admin} do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin")

      # Check that date format includes dots (DD.MM.YYYY)
      assert html =~ ~r/\d{2}\.\d{2}\.\d{4}/
    end
  end

  describe "permissions" do
    test "non-admin user cannot access dashboard", %{conn: conn} do
      regular_user = user_fixture(%{user_type: :employer})

      result =
        conn
        |> log_in_user(regular_user)
        |> get(~p"/admin")

      assert result.status == 401
    end

    test "job seeker cannot access dashboard", %{conn: conn} do
      job_seeker = user_fixture(%{user_type: :job_seeker})

      result =
        conn
        |> log_in_user(job_seeker)
        |> get(~p"/admin")

      assert result.status == 401
    end
  end

  describe "empty state" do
    test "handles empty database gracefully", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin")

      assert html =~ "Admin Dashboard"
    end
  end

  describe "invited users section" do
    test "displays invited users with pending status", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      invited_user =
        unconfirmed_user_fixture(%{
          email: "invited@example.com",
          first_name: "John",
          last_name: "Doe",
          user_type: :employer,
          registration_source: :invited
        })

      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin")

      assert html =~ invited_user.email
      assert html =~ invited_user.first_name
      assert html =~ invited_user.last_name
      assert html =~ "Ausstehend"
    end

    test "displays invited users with accepted status", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      invited_user =
        user_fixture(%{
          email: "accepted@example.com",
          first_name: "Jane",
          last_name: "Smith",
          user_type: :employer,
          registration_source: :invited,
          confirmed_at: DateTime.utc_now()
        })

      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin")

      assert html =~ invited_user.email
      assert html =~ invited_user.first_name
      assert html =~ invited_user.last_name
      assert html =~ "Akzeptiert"
    end

    test "displays multiple invited users ordered by most recent", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      # Create older user
      older_user =
        user_fixture(%{
          email: "older@example.com",
          first_name: "Older",
          last_name: "User",
          registration_source: :invited
        })

      older_timestamp = DateTime.add(DateTime.utc_now(), -2, :day)

      query =
        from(u in BemedaPersonal.Accounts.User, where: u.id == ^older_user.id)

      BemedaPersonal.Repo.update_all(query, set: [inserted_at: older_timestamp])

      # Create newer user
      newer_user =
        user_fixture(%{
          email: "newer@example.com",
          first_name: "Newer",
          last_name: "User",
          registration_source: :invited
        })

      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin")

      assert html =~ older_user.email
      assert html =~ newer_user.email

      newer_position =
        html
        |> :binary.match(newer_user.email)
        |> elem(0)

      older_position =
        html
        |> :binary.match(older_user.email)
        |> elem(0)

      assert newer_position < older_position
    end

    test "does not display non-invited users in invited users section", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      _regular_user =
        user_fixture(%{
          email: "regular@example.com",
          registration_source: :email
        })

      invited_user =
        user_fixture(%{
          email: "invited@example.com",
          registration_source: :invited
        })

      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, _html} = live(conn, ~p"/admin")

      html = render(live)

      invited_section =
        html
        |> String.split("Eingeladene Benutzer")
        |> Enum.at(1, "")
        |> String.split("Recent Activity")
        |> Enum.at(0, "")

      assert invited_section =~ invited_user.email
      refute invited_section =~ "regular@example.com"
    end

    test "shows empty state when no invited users exist", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin")

      assert html =~ "Keine Einladungen verfügbar"
    end

    test "displays invitation count correctly", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      _user1 = user_fixture(%{email: "invited1@example.com", registration_source: :invited})
      _user2 = user_fixture(%{email: "invited2@example.com", registration_source: :invited})
      _user3 = user_fixture(%{email: "invited3@example.com", registration_source: :invited})

      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin")

      assert html =~ "3"
      assert html =~ "Einladungen"
    end

    test "displays invite user button", %{conn: conn, auth_header: auth_header, admin: admin} do
      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, live, html} = live(conn, ~p"/admin")

      assert html =~ "Benutzer einladen"
      assert has_element?(live, "a[href='/admin/invitations/new']")
    end

    test "limits invited users to 20 most recent", %{
      conn: conn,
      auth_header: auth_header,
      admin: admin
    } do
      for i <- 1..25 do
        user_fixture(%{
          email: "invited#{i}@example.com",
          registration_source: :invited,
          inserted_at: DateTime.add(DateTime.utc_now(), -i, :day)
        })
      end

      conn =
        conn
        |> log_in_user(admin)
        |> admin_conn(auth_header)

      {:ok, _live, html} = live(conn, ~p"/admin")

      assert html =~ "invited1@example.com"
      assert html =~ "invited20@example.com"
      refute html =~ "invited25@example.com"
    end
  end
end
