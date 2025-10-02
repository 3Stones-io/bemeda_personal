defmodule BemedaPersonalWeb.Features.CommonSteps do
  use Cucumber.StepDefinition
  use BemedaPersonalWeb, :verified_routes

  import ExUnit.Assertions
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.AccountsFixtures
  alias BemedaPersonalWeb.Endpoint

  @endpoint Endpoint

  @type context :: map()

  # ============================================================================
  # Application State Steps
  # ============================================================================

  step "the application is running", context do
    # Verify server is responsive (optional health check)
    # For now, just pass through context
    {:ok, context}
  end

  # ============================================================================
  # Authentication Steps
  # ============================================================================

  step "I am logged in as {string}", %{args: [user_type]} = context do
    user_type_atom = String.to_existing_atom(user_type)

    user =
      AccountsFixtures.user_fixture(
        user_type: user_type_atom,
        confirmed_at: DateTime.utc_now()
      )

    conn =
      build_conn()
      |> Phoenix.ConnTest.init_test_session(%{})
      |> Plug.Conn.put_session(:user_token, Accounts.generate_user_session_token(user))
      |> Plug.Conn.put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(user.id)}")

    updated_context =
      context
      |> Map.put(:conn, conn)
      |> Map.put(:current_user, user)

    {:ok, updated_context}
  end

  # ============================================================================
  # Navigation Steps
  # ============================================================================

  step "I visit the job details page", context do
    job = context.current_job
    conn = context.conn

    {:ok, view, _html} = live(conn, ~p"/jobs/#{job}")

    {:ok, Map.put(context, :view, view)}
  end

  step "I click {string}", %{args: [button_text]} = context do
    view = context.view

    html =
      view
      |> element("a, button", button_text)
      |> render_click()

    {:ok, Map.put(context, :last_html, html)}
  end

  # ============================================================================
  # Form Interaction Steps
  # ============================================================================

  step "I fill in {string} with {string}", %{args: [field_name, value]} = context do
    # Store form data for later submission
    form_data = Map.get(context, :form_data, %{})
    updated_form_data = Map.put(form_data, field_name, value)

    {:ok, Map.put(context, :form_data, updated_form_data)}
  end

  step "I click {string} without filling cover letter", %{args: [_button_text]} = context do
    view = context.view

    # Submit form with empty cover letter
    html =
      view
      |> form("#application-form", %{job_application: %{cover_letter: ""}})
      |> render_submit()

    {:ok, Map.put(context, :last_html, html)}
  end

  # ============================================================================
  # Assertion Steps
  # ============================================================================

  step "I should see {string}", %{args: [text]} = context do
    html = context.last_html || render(context.view)
    assert html =~ text, "Expected to see '#{text}' in the page"
    {:ok, context}
  end

  step "I should not see {string}", %{args: [text]} = context do
    html = context.last_html || render(context.view)
    refute html =~ text, "Expected NOT to see '#{text}' in the page"
    {:ok, context}
  end

  step "I should not see {string} button", %{args: [button_text]} = context do
    html = context.last_html || render(context.view)
    refute html =~ button_text
    {:ok, context}
  end
end
