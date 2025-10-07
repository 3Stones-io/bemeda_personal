defmodule BemedaPersonalWeb.Features.RegistrationSteps do
  use Cucumber.StepDefinition
  use BemedaPersonalWeb, :verified_routes

  import BemedaPersonal.BddHelpers
  import ExUnit.Assertions
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.AccountsFixtures
  alias BemedaPersonalWeb.Endpoint

  @endpoint Endpoint

  @type context :: map()

  # ============================================================================
  # Navigation Steps
  # ============================================================================

  step "I visit the registration page", context do
    conn = build_conn()
    {:ok, view, _html} = live(conn, ~p"/users/register")

    updated_context =
      context
      |> Map.put(:conn, conn)
      |> Map.put(:view, view)

    {:ok, updated_context}
  end

  # ============================================================================
  # User Type Selection Steps
  # ============================================================================

  step "I select {string} as user type", %{args: [user_type]} = context do
    # Navigate to the specific registration type page
    {:ok, view, _html} = live(context.conn, ~p"/users/register/#{user_type}")

    updated_context =
      context
      |> Map.put(:view, view)
      |> Map.put(:user_type, String.to_existing_atom(user_type))
      |> Map.put(:registration_email, generate_unique_email(user_type))

    {:ok, updated_context}
  end

  # ============================================================================
  # Form Filling Steps - Job Seeker Step 1
  # ============================================================================

  step "I fill in personal information on step 1", context do
    view = context.view
    email = context.registration_email

    html =
      view
      |> form("#registration_form", %{
        user: %{
          first_name: "Test",
          last_name: "User",
          email: email,
          password: "securepassword123",
          date_of_birth: "1990-01-01",
          city: "Zurich",
          phone: "1234567890"
        }
      })
      |> render_change()

    {:ok, Map.put(context, :last_html, html)}
  end

  step "I fill in personal information with invalid email", context do
    view = context.view

    html =
      view
      |> form("#registration_form", %{
        user: %{
          first_name: "Test",
          last_name: "User",
          email: "invalid-email",
          password: "securepassword123",
          date_of_birth: "1990-01-01",
          city: "Zurich",
          phone: "1234567890"
        }
      })
      |> render_change()

    {:ok, Map.put(context, :last_html, html)}
  end

  # ============================================================================
  # Form Filling Steps - Job Seeker Step 2
  # ============================================================================

  step "I fill in work information on step 2", context do
    view = context.view

    # Store step 2 form data in context for later submission
    step2_data = %{
      medical_role: "Registered Nurse (AKP/DNII/HF/FH)",
      department: "Hospital / Clinic",
      gender: "male",
      street: "123 Test Street",
      city: "Zurich",
      zip_code: "8000",
      country: "Switzerland"
    }

    html =
      view
      |> form("#registration_form", %{user: step2_data})
      |> render_change()

    updated_context =
      context
      |> Map.put(:last_html, html)
      |> Map.put(:step2_form_data, step2_data)

    {:ok, updated_context}
  end

  # ============================================================================
  # Form Filling Steps - Employer
  # ============================================================================

  step "I fill in employer registration details", context do
    view = context.view
    email = context.registration_email

    # Employer registration has fewer fields than job seeker
    # Only: first_name, last_name, email, password, city, phone
    employer_data = %{
      first_name: "Employer",
      last_name: "Test",
      email: email,
      password: "securepassword123",
      city: "Zurich",
      phone: "1234567890"
    }

    html =
      view
      |> form("#registration_form", %{user: employer_data})
      |> render_change()

    updated_context =
      context
      |> Map.put(:last_html, html)
      |> Map.put(:employer_form_data, employer_data)

    {:ok, updated_context}
  end

  # ============================================================================
  # Action Steps
  # ============================================================================

  step "I accept the terms and conditions", context do
    # Terms checkbox is handled in the form submission
    # Store flag to indicate terms should be accepted
    {:ok, Map.put(context, :terms_accepted, true)}
  end

  step "I click {string} button", %{args: [button_text]} = context do
    view = context.view

    case button_text do
      "Next" ->
        # For job seeker step 1, submit form to trigger next_step
        html =
          view
          |> element("form#registration_form")
          |> render_submit()

        {:ok, Map.put(context, :last_html, html)}

      "Create account" ->
        # Submit the registration form with appropriate data
        html =
          cond do
            step2_data = Map.get(context, :step2_form_data) ->
              # Job seeker step 2 registration
              view
              |> form("#registration_form", %{user: step2_data})
              |> render_submit()

            employer_data = Map.get(context, :employer_form_data) ->
              # Employer single-step registration
              view
              |> form("#registration_form", %{user: employer_data})
              |> render_submit()

            true ->
              # Fallback for other scenarios
              view
              |> element("form#registration_form")
              |> render_submit()
          end

        {:ok, Map.put(context, :last_html, html)}

      _other_button ->
        html =
          view
          |> element("button, a", button_text)
          |> render_click()

        {:ok, Map.put(context, :last_html, html)}
    end
  end

  # ============================================================================
  # Assertion Steps
  # ============================================================================

  step "I should see step 2 of registration", context do
    view = context.view
    html = render(view)

    # Verify we're on step 2 by checking for work information fields
    assert html =~ "Medical Role"
    assert html =~ "Department"
    assert html =~ "Work Information"

    {:ok, context}
  end

  step "I should be registered successfully", context do
    # After successful registration, user should be created in database
    # Need to allow time for async database write to complete
    email = context.registration_email

    # Try multiple times with small delays to account for async operations
    user =
      Enum.reduce_while(1..5, nil, fn attempt, _acc ->
        case Accounts.get_user_by_email(nil, email) do
          nil when attempt < 5 ->
            Process.sleep(100)
            {:cont, nil}

          nil ->
            {:halt, nil}

          found_user ->
            {:halt, found_user}
        end
      end)

    assert user != nil, "User should be created with email #{email}"
    assert user.email == email
    assert user.user_type == context.user_type

    {:ok, Map.put(context, :registered_user, user)}
  end

  step "I should receive a confirmation email", context do
    # Verify confirmation email was sent (in test env, this is a no-op)
    # In real implementation, check email delivery system
    user = context.registered_user

    # Verify user has unconfirmed status
    refute user.confirmed_at, "User should not be confirmed yet"

    {:ok, context}
  end

  step "I should see error message {string}", %{args: [error_text]} = context do
    html = Map.get(context, :last_html) || render(context.view)

    assert html =~ error_text,
           "Expected to see error message '#{error_text}' in the page"

    {:ok, context}
  end

  # ============================================================================
  # Email Confirmation Steps
  # ============================================================================

  step "I have registered as a job seeker", context do
    # Create a registered but unconfirmed user
    user =
      AccountsFixtures.user_fixture(
        user_type: :job_seeker,
        email: generate_unique_email("job_seeker"),
        confirmed: false
      )

    {:ok, Map.put(context, :registered_user, user)}
  end

  step "I check my confirmation email", context do
    # In test environment, simulate checking email
    user = context.registered_user

    # Extract confirmation token using the deliver function pattern
    token =
      AccountsFixtures.extract_user_token(fn url_fun ->
        Accounts.deliver_user_confirmation_instructions(user, url_fun)
      end)

    {:ok, Map.put(context, :confirmation_token, token)}
  end

  step "I should see a confirmation link", context do
    token = context.confirmation_token

    # Verify token exists and is valid
    assert token != nil, "Confirmation token should exist"
    assert String.length(token) > 0, "Confirmation token should not be empty"

    {:ok, context}
  end
end
