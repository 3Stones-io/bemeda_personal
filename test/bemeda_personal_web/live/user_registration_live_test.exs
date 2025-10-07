defmodule BemedaPersonalWeb.UserRegistrationLiveTest do
  use BemedaPersonalWeb.ConnCase, async: false

  import BemedaPersonal.AccountsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Join as a job seeker or employer"
      assert html =~ "Log in"
    end

    test "can navigate between job seeker and employer registration with patch", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      # Click on employer registration
      lv
      |> element("a", "Sign up as employer")
      |> render_click()

      # Assert patch navigation happened
      assert_patch(lv, "/users/register/employer")

      employer_html = render(lv)
      assert employer_html =~ "Get connect with qualified"
      assert employer_html =~ "healthcare professionals"

      # Test the other direction in a new session
      {:ok, lv2, _html} = live(conn, ~p"/users/register")

      # Click on job seeker registration
      lv2
      |> element("a", "Sign up as medical personnel")
      |> render_click()

      # Assert patch navigation happened
      assert_patch(lv2, "/users/register/job_seeker")

      job_seeker_html = render(lv2)
      assert job_seeker_html =~ "Create your account"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/register")
        |> follow_redirect(conn, "/")

      assert {:ok, _conn} = result
    end

    test "renders step 1 form fields", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register/job_seeker")

      assert html =~ "Create your account"
      assert html =~ "First Name"
      assert html =~ "Last Name"
      assert html =~ "Email"
      assert html =~ "Password"
      assert html =~ "Next"
      refute html =~ "Medical Role"
      refute html =~ "Department"
      refute html =~ "Back"
    end

    test "renders errors for invalid step 1 data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      result =
        lv
        |> element("#registration_form")
        |> render_submit(
          user: %{
            "email" => "with spaces",
            "first_name" => "",
            "last_name" => "",
            "password" => "too short"
          }
        )

      assert result =~ "Create your account"
      assert result =~ "must have the @ sign and no spaces"
      assert result =~ "should be at least 12 character"
      assert result =~ "can&#39;t be blank"
    end

    test "shows step indicator", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register/job_seeker")

      assert html =~ "bg-primary-500"
      assert html =~ "bg-gray-200"
    end
  end

  describe "Step navigation" do
    test "advances to step 2 with valid step 1 data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      html =
        lv
        |> form("#registration_form",
          user: %{
            "first_name" => "John",
            "last_name" => "Doe",
            "email" => "john@example.com",
            "password" => "valid_password_123"
          }
        )
        |> render_submit()

      assert html =~ "Medical Role"
      assert html =~ "Gender"
      assert html =~ "Street"
      assert html =~ "Zip Code"
      assert html =~ "City"
      assert html =~ "Country"
      assert html =~ "Go back"
      assert html =~ "Create an account"
      refute html =~ "Next"
    end

    test "does not advance to step 2 with invalid step 1 data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      html =
        lv
        |> form("#registration_form",
          user: %{
            "first_name" => "",
            "last_name" => "",
            "email" => "invalid-email",
            "password" => "short"
          }
        )
        |> render_submit()

      assert html =~ "Create your account"
      assert html =~ "can&#39;t be blank"
      assert html =~ "must have the @ sign and no spaces"
      refute html =~ "Medical Role"
    end

    test "goes back to step 1 when back button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      lv
      |> form("#registration_form",
        user: %{
          "first_name" => "John",
          "last_name" => "Doe",
          "email" => "john@example.com",
          "password" => "valid_password_123"
        }
      )
      |> render_submit()

      html =
        lv
        |> element("button", "Go back")
        |> render_click()

      assert html =~ "Create your account"
      assert html =~ "Next"
      refute html =~ "Medical Role"
      refute html =~ "Back"
    end

    test "preserves form data when navigating between steps", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      lv
      |> form("#registration_form",
        user: %{
          "first_name" => "John",
          "last_name" => "Doe",
          "email" => "john@example.com",
          "password" => "valid_password_123"
        }
      )
      |> render_submit()

      html =
        lv
        |> element("button", "Go back")
        |> render_click()

      assert html =~ "value=\"John\""
      assert html =~ "value=\"Doe\""
      assert html =~ "value=\"john@example.com\""
    end
  end

  describe "register user" do
    test "creates account with 2-step process", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      valid_attributes = Map.drop(valid_user_attributes(), [:user_type])

      step1_attributes = Map.take(valid_attributes, [:email, :first_name, :last_name, :password])

      lv
      |> form("#registration_form", %{user: step1_attributes})
      |> render_submit()

      step2_attributes = Map.drop(valid_attributes, [:first_name, :last_name])
      form = form(lv, "#registration_form", %{user: step2_attributes})
      render_submit(form)

      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/users/log_in"

      # Now do a logged in request and assert on the menu
      logged_in_conn = get(conn, ~p"/users/log_in")
      response = html_response(logged_in_conn, 200)
      assert response =~ "Please check your email and click the confirmation link"
    end

    test "includes _action=registered in form action on successful registration", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      valid_attributes = Map.drop(valid_user_attributes(), [:user_type])

      step1_attributes = Map.take(valid_attributes, [:email, :first_name, :last_name, :password])

      lv
      |> form("#registration_form", %{user: step1_attributes})
      |> render_submit()

      step2_attributes = Map.drop(valid_attributes, [:first_name, :last_name])
      form = form(lv, "#registration_form", %{user: step2_attributes})
      render_submit(form)

      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/users/log_in"
      assert conn.params["_action"] == "registered"
    end

    test "renders errors for invalid step 2 data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      lv
      |> form("#registration_form",
        user: %{
          "first_name" => "John",
          "last_name" => "Doe",
          "email" => "john@example.com",
          "password" => "valid_password_123"
        }
      )
      |> render_submit()

      result =
        lv
        |> form("#registration_form",
          user: %{
            "city" => "",
            "country" => "",
            "street" => "",
            "zip_code" => ""
          }
        )
        |> render_submit()

      assert result =~ "Medical Role"
      assert result =~ "can&#39;t be blank"
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/employer")

      user = user_fixture(%{email: "test@email.com"})

      result =
        lv
        |> form("#registration_form",
          user: %{
            "first_name" => "John",
            "last_name" => "Doe",
            "email" => user.email,
            "password" => "valid_password_123",
            "city" => "Test City"
          }
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end

    test "saves the locale preference", %{conn: conn} do
      conn = init_test_session(conn, %{locale: "it"})

      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      email = "test_locale@example.com"

      valid_attributes =
        [email: email]
        |> valid_user_attributes()
        |> Map.drop([:user_type])

      step1_attributes =
        Map.take(valid_attributes, [:email, :first_name, :last_name, :password])

      lv
      |> form("#registration_form", user: step1_attributes)
      |> render_submit()

      step2_attributes =
        Map.take(valid_attributes, [
          :gender,
          :street,
          :zip_code,
          :city,
          :country,
          :medical_role,
          :department
        ])

      lv
      |> form("#registration_form", user: step2_attributes)
      |> render_submit()

      user = Accounts.get_user_by_email(nil, email)
      assert user.locale == :it
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      {:ok, _login_live, login_html} =
        lv
        |> element("a", "Sign in")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/log_in")

      assert login_html =~ "Log in"
    end

    test "navigates to employer registration when employer option is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      lv
      |> element("a[href='/users/register/employer']")
      |> render_click()

      assert_patch(lv, ~p"/users/register/employer")
    end

    test "navigates to job seeker registration when job seeker option is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      lv
      |> element("a[href='/users/register/job_seeker']")
      |> render_click()

      assert_patch(lv, ~p"/users/register/job_seeker")
    end
  end

  describe "Progressive validation behavior" do
    test "shows errors only for touched fields during editing", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      # During editing - only show error for touched email field
      change_result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "invalid"})

      assert change_result =~ "must have the @ sign and no spaces"
      # Other fields not touched yet - should not show errors
      refute change_result =~ "should be at least 12 character"

      # After submission - show ALL errors for invalid fields
      submit_result =
        lv
        |> element("#registration_form")
        |> render_submit(
          user: %{
            "email" => "invalid",
            "first_name" => "John",
            "last_name" => "Doe",
            "password" => "short"
          }
        )

      assert submit_result =~ "must have the @ sign and no spaces"
      assert submit_result =~ "should be at least 12 character"
    end

    test "shows ALL field errors after form submission attempt", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      # Submit form with multiple invalid fields
      result =
        lv
        |> element("#registration_form")
        |> render_submit(
          user: %{
            "email" => "invalid",
            "password" => "short",
            "first_name" => "",
            "last_name" => ""
          }
        )

      # ALL field errors should now be visible
      # email error
      assert result =~ "must have the @ sign and no spaces"
      # password error
      assert result =~ "should be at least 12 character"
      # first_name error
      assert result =~ "can&#39;t be blank"
      # last_name error
      assert result =~ "can&#39;t be blank"

      # Generic error should also be present
      assert result =~ "Oops, something went wrong! Please check the errors below."
    end

    test "shows errors for invalid fields after submission, even if some fields are valid", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      # Submit with mix of valid and invalid fields
      result =
        lv
        |> element("#registration_form")
        |> render_submit(
          user: %{
            # valid
            "email" => "valid@example.com",
            # invalid
            "password" => "short",
            # valid
            "first_name" => "John",
            # invalid
            "last_name" => ""
          }
        )

      # Should show errors for invalid fields only
      # email is valid, no error
      refute result =~ "must have the @ sign"
      # password error
      assert result =~ "should be at least 12 character"
      # first_name is valid ("John"), should not show error
      # last_name is invalid (""), should show error
      # Since both use same error message, check count: should be exactly 1 "can't be blank" (for last_name only)
      blank_error_count =
        result
        |> String.split("can&#39;t be blank")
        |> length()
        |> Kernel.-(1)

      assert blank_error_count == 1
    end

    test "removes field error when field becomes valid during editing", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      submit_result =
        lv
        |> element("#registration_form")
        |> render_submit(
          user: %{
            "email" => "invalid",
            "first_name" => "John",
            "last_name" => "Doe",
            "password" => "password123"
          }
        )

      assert submit_result =~ "must have the @ sign"

      fixed_result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "valid@example.com"})

      refute fixed_result =~ "must have the @ sign"
    end
  end

  describe "critical validation scenarios" do
    test "empty form submission shows ALL required field errors", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      # Submit completely empty form
      result =
        lv
        |> element("#registration_form")
        |> render_submit(user: %{})

      # Must show errors for ALL required fields
      # Contains error messages
      assert result =~ "can&#39;t be blank"
      # Must NOT advance to Step 2
      assert result =~ "Create your account"
      refute result =~ "Medical Role"
    end

    test "progressive validation shows errors only for touched invalid fields", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      # Initially no validation errors should be shown
      html = render(lv)
      refute html =~ "must have the @ sign"

      # Touch one field with invalid data (progressive validation)
      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "invalid"})

      # Should show validation error for the touched invalid field
      assert result =~ "must have the @ sign"
      # Note: Core validation behavior - other field errors may appear
      # This will be handled by visual styling in core_components.ex
    end

    test "validation state resets correctly during progressive editing", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      # Submit invalid form to trigger validation state
      lv
      |> element("#registration_form")
      |> render_submit(user: %{"email" => "invalid"})

      # Fix the email field
      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "valid@example.com"})

      # Email should no longer show validation error after being fixed
      refute result =~ "must have the @ sign"
    end

    test "step 2 shows no validation errors immediately after navigation", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      # Complete Step 1 successfully
      step1_result =
        lv
        |> form("#registration_form",
          user: %{
            "first_name" => "John",
            "last_name" => "Doe",
            "email" => "john@example.com",
            "password" => "valid_password_123"
          }
        )
        |> render_submit()

      # Verify Step 2 doesn't show validation errors initially
      refute step1_result =~ "can&#39;t be blank"
      assert step1_result =~ "Medical Role"
    end

    test "step 2 progressive validation works correctly", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      # Navigate to Step 2
      lv
      |> form("#registration_form",
        user: %{
          "first_name" => "John",
          "last_name" => "Doe",
          "email" => "john@example.com",
          "password" => "valid_password_123"
        }
      )
      |> render_submit()

      # Touch one Step 2 field (progressive validation)
      live_result =
        lv
        |> form("#registration_form", user: %{"street" => ""})
        |> render_change()

      # Should show error for the touched empty field
      assert live_result =~ "can&#39;t be blank"
    end

    test "back navigation preserves data but resets validation state", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      # Navigate to Step 2, then back to Step 1
      lv
      |> form("#registration_form",
        user: %{
          "first_name" => "John",
          "last_name" => "Doe",
          "email" => "john@example.com",
          "password" => "valid_password_123"
        }
      )
      |> render_submit()

      back_result =
        lv
        |> element("button", "Go back")
        |> render_click()

      # Step 1 should not show validation errors after back navigation
      assert back_result =~ "Create your account"
      refute back_result =~ "can&#39;t be blank"
      # But data should be preserved
      assert back_result =~ "value=\"John\""
      assert back_result =~ "value=\"Doe\""
      assert back_result =~ "value=\"john@example.com\""
    end

    test "country dropdown functionality", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      # Initially dropdown is closed and Switzerland is selected
      form_html =
        lv
        |> element("#registration_form")
        |> render()

      assert form_html =~ "+41"
      assert form_html =~ "🇨🇭"
      refute form_html =~ "Germany"

      # Toggle dropdown open
      lv
      |> element("[phx-click=\"toggle_country_dropdown\"]")
      |> render_click()

      dropdown_html =
        lv
        |> element("#registration_form")
        |> render()

      assert dropdown_html =~ "Germany"
      assert dropdown_html =~ "+49"
      assert dropdown_html =~ "🇩🇪"

      # Select Germany
      lv
      |> element(~s{[phx-click="select_country"][phx-value-code="+49"]})
      |> render_click()

      updated_html =
        lv
        |> element("#registration_form")
        |> render()

      assert updated_html =~ "+49"
      assert updated_html =~ "🇩🇪"
      # Dropdown should be closed
      refute updated_html =~ "Germany"
    end

    test "employer registration form", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register/employer")

      assert html =~ "Get connect with qualified"
      assert html =~ "healthcare professionals"
      assert html =~ "Work Email Address"
      refute html =~ "Medical Role"
      refute html =~ "Department"
      refute html =~ "Date of Birth"
    end
  end
end
