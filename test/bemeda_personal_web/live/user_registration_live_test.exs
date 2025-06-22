defmodule BemedaPersonalWeb.UserRegistrationLiveTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Join as a client or freelancer"
      assert html =~ "Log in"
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

      assert html =~ "Step 1: Basic Information"
      assert html =~ "First Name"
      assert html =~ "Last Name"
      assert html =~ "Email"
      assert html =~ "Password"
      assert html =~ "Continue"
      refute html =~ "Gender"
      refute html =~ "Street"
      refute html =~ "Back"
    end

    test "renders errors for invalid step 1 data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      result =
        lv
        |> element("#registration_form")
        |> render_change(
          user: %{
            "email" => "with spaces",
            "first_name" => "",
            "last_name" => "",
            "password" => "too short"
          }
        )

      assert result =~ "Register for an account"
      assert result =~ "must have the @ sign and no spaces"
      assert result =~ "should be at least 12 character"
      assert result =~ "can&#39;t be blank"
    end

    test "shows step indicator", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register/job_seeker")

      assert html =~ "bg-brand text-white"
      assert html =~ "bg-gray-200 text-gray-600"
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

      assert html =~ "Step 2: Personal Information"
      assert html =~ "Gender"
      assert html =~ "Street"
      assert html =~ "ZIP Code"
      assert html =~ "City"
      assert html =~ "Country"
      assert html =~ "Back"
      assert html =~ "Create an account"
      refute html =~ "Continue"
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

      assert html =~ "Step 1: Basic Information"
      assert html =~ "can&#39;t be blank"
      assert html =~ "must have the @ sign and no spaces"
      refute html =~ "Step 2: Personal Information"
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
        |> element("button", "Back")
        |> render_click()

      assert html =~ "Step 1: Basic Information"
      assert html =~ "Continue"
      refute html =~ "Step 2: Personal Information"
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
        |> element("button", "Back")
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
      |> form("#registration_form", user: step1_attributes)
      |> render_submit()

      step2_attributes = Map.drop(valid_attributes, [:first_name, :last_name])
      form = form(lv, "#registration_form", user: step2_attributes)
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
      |> form("#registration_form", user: step1_attributes)
      |> render_submit()

      step2_attributes = Map.drop(valid_attributes, [:first_name, :last_name])
      form = form(lv, "#registration_form", user: step2_attributes)
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

      assert result =~ "Step 2: Personal Information"
      assert result =~ "can&#39;t be blank"
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/employer")

      user = user_fixture(%{email: "test@email.com"})

      step1_result =
        lv
        |> form("#registration_form",
          user: %{
            "first_name" => "John",
            "last_name" => "Doe",
            "email" => user.email,
            "password" => "valid_password_123"
          }
        )
        |> render_submit()

      assert step1_result =~ "Step 2: Personal Information"

      step2_result =
        lv
        |> form("#registration_form",
          user: %{
            "city" => "Test City",
            "country" => "Test Country",
            "street" => "123 Main St",
            "zip_code" => "12345"
          }
        )
        |> render_submit()

      assert step2_result =~ "has already been taken"
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
        Map.take(valid_attributes, [:gender, :street, :zip_code, :city, :country])

      lv
      |> form("#registration_form", user: step2_attributes)
      |> render_submit()

      user = Accounts.get_user_by_email(email)
      assert user.locale == :it
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      {:ok, _login_live, login_html} =
        lv
        |> element(~s|main a:fl-contains("Log in")|)
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

      # User starts typing email - should show email errors only
      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "invalid"})

      assert result =~ "must have the @ sign and no spaces"
      # No password error yet - check for absence of password-specific error message
      refute result =~ "should be at least 12 character"

      # User continues with empty password - still no password error until touched
      change_result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "invalid", "password" => ""})

      assert change_result =~ "must have the @ sign and no spaces"
      # Password not touched yet
      refute change_result =~ "should be at least 12 character"
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

      # First make field invalid
      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "invalid"})

      assert result =~ "must have the @ sign"

      # Then fix the field
      fixed_result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "valid@example.com"})

      refute fixed_result =~ "must have the @ sign"
    end
  end
end
