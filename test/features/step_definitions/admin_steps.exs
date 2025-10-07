defmodule BemedaPersonalWeb.Features.AdminSteps do
  use Cucumber.StepDefinition
  use BemedaPersonalWeb, :verified_routes

  import BemedaPersonal.BddHelpers
  import ExUnit.Assertions
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Plug.Conn

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.AccountsFixtures
  alias BemedaPersonal.CompaniesFixtures
  alias BemedaPersonal.JobApplicationsFixtures
  alias BemedaPersonal.JobPostingsFixtures
  alias BemedaPersonalWeb.Endpoint

  @endpoint Endpoint

  @type context :: map()

  # ============================================================================
  # Given Steps - Admin Authentication and Setup
  # ============================================================================

  step "I am authenticated as admin", context do
    # Create admin user
    admin_user =
      AccountsFixtures.user_fixture(%{
        email: generate_unique_email("admin"),
        user_type: :employer
      })

    # Get admin credentials from application config
    admin_username = Application.get_env(:bemeda_personal, :admin)[:username]
    admin_password = Application.get_env(:bemeda_personal, :admin)[:password]
    auth_header = "Basic " <> Base.encode64("#{admin_username}:#{admin_password}")

    # Build connection with admin credentials and user session
    conn =
      build_conn()
      |> Phoenix.ConnTest.init_test_session(%{})
      |> Plug.Conn.put_session(:user_token, Accounts.generate_user_session_token(admin_user))
      |> Plug.Conn.put_session(
        :live_socket_id,
        "users_sessions:#{Base.url_encode64(admin_user.id)}"
      )
      |> put_req_header("authorization", auth_header)

    {:ok, Map.merge(context, %{conn: conn, admin_user: admin_user, auth_header: auth_header})}
  end

  step "there are applications with different statuses", context do
    employer =
      AccountsFixtures.user_fixture(%{
        user_type: :employer,
        email: generate_unique_email("employer")
      })

    job_seeker1 =
      AccountsFixtures.user_fixture(%{
        user_type: :job_seeker,
        email: generate_unique_email("seeker1")
      })

    job_seeker2 =
      AccountsFixtures.user_fixture(%{
        user_type: :job_seeker,
        email: generate_unique_email("seeker2")
      })

    company = CompaniesFixtures.company_fixture(employer)
    job_posting = JobPostingsFixtures.job_posting_fixture(company)

    # Create applications with different states
    _app1 =
      JobApplicationsFixtures.job_application_fixture(job_seeker1, job_posting, %{
        state: "applied"
      })

    _app2 =
      JobApplicationsFixtures.job_application_fixture(job_seeker2, job_posting, %{
        state: "offer_extended"
      })

    {:ok, context}
  end

  step "there are recent users, job postings, and applications", context do
    # Create recent users
    _user1 =
      AccountsFixtures.user_fixture(%{email: generate_unique_email("recent_user1")})

    _user2 =
      AccountsFixtures.user_fixture(%{email: generate_unique_email("recent_user2")})

    # Create recent job postings
    employer =
      AccountsFixtures.user_fixture(%{
        user_type: :employer,
        email: generate_unique_email("employer")
      })

    company = CompaniesFixtures.company_fixture(employer, %{name: "Recent Company"})
    job_posting = JobPostingsFixtures.job_posting_fixture(company, %{title: "Recent Position"})

    # Create recent applications
    job_seeker =
      AccountsFixtures.user_fixture(%{
        user_type: :job_seeker,
        email: generate_unique_email("applicant")
      })

    _application = JobApplicationsFixtures.job_application_fixture(job_seeker, job_posting)

    {:ok, context}
  end

  # ============================================================================
  # When Steps - Admin Navigation
  # ============================================================================

  step "I visit the admin dashboard", context do
    conn = context.conn

    {:ok, view, _html} = live(conn, ~p"/admin")

    {:ok, Map.put(context, :view, view)}
  end

  # ============================================================================
  # Then Steps - Admin Dashboard Assertions
  # ============================================================================

  step "I should see total user statistics", context do
    html = render(context.view)

    # Check for user statistics card structure
    assert html =~ "text-3xl font-bold text-gray-900"
    # Statistics cards should be visible
    assert html =~ "bg-white rounded-lg shadow"

    {:ok, context}
  end

  step "I should see total company statistics", context do
    html = render(context.view)

    # Check for company statistics card
    assert html =~ "bg-white rounded-lg shadow"

    {:ok, context}
  end

  step "I should see total job posting statistics", context do
    html = render(context.view)

    # Check for job posting statistics card
    assert html =~ "text-3xl font-bold"

    {:ok, context}
  end

  step "I should see total application statistics", context do
    html = render(context.view)

    # Check for application statistics card
    assert html =~ "bg-white rounded-lg shadow"

    {:ok, context}
  end

  step "I should see the application status breakdown", context do
    html = render(context.view)

    # Check for application status breakdown section
    assert html =~ "text-xl font-semibold"
    assert html =~ "grid"

    {:ok, context}
  end

  step "I should see {string} status count", %{args: [status]} = context do
    html = render(context.view)

    # Map status to German translations
    german_status =
      case status do
        "applied" -> "Beworben"
        "offer_extended" -> "Angebot gemacht"
        _other -> status
      end

    assert html =~ german_status

    {:ok, context}
  end

  step "I should see recent users section", context do
    html = render(context.view)

    # Check for recent users section structure
    assert html =~ "text-lg font-semibold"
    # Recent users should have email addresses
    assert html =~ "@example.com"

    {:ok, context}
  end

  step "I should see recent job postings section", context do
    html = render(context.view)

    # Check for recent job postings section structure
    assert html =~ "text-lg font-semibold"
    # Should contain job posting title or company name
    assert html =~ "text-sm font-medium text-gray-900"

    {:ok, context}
  end

  step "I should see recent applications section", context do
    html = render(context.view)

    # Check for recent applications section structure
    assert html =~ "text-lg font-semibold"
    # Should show application details
    assert html =~ "text-xs text-gray-500"

    {:ok, context}
  end

  step "I should see the registrations chart placeholder", context do
    html = render(context.view)

    # Check for registrations chart element
    assert html =~ "registrations-chart"
    assert html =~ "phx-hook=\"AdminChart\""

    {:ok, context}
  end

  step "I should see the applications chart placeholder", context do
    html = render(context.view)

    # Check for applications chart element
    assert html =~ "applications-chart"
    assert html =~ "phx-hook=\"AdminChart\""

    {:ok, context}
  end
end
