defmodule BemedaPersonalWeb.UserLive.RegistrationTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import Phoenix.LiveViewTest

  describe "registration page - step one" do
    test "renders account type selection page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Join as a job seeker or employer"
      assert html =~ "Employer"
      assert html =~ "Medical Personnel"
      assert html =~ "Sign up as employer"
      assert html =~ "Sign up as medical personnel"
      assert html =~ "Already have an account?"
      assert html =~ "Sign in"
    end

    test "displays employer description correctly", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~
               "Get connected with qualified health care professionals and streamline your hiring process effortlessly."
    end

    test "displays job seeker description correctly", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~
               "Explore job opportunities, connect with top healthcare employers, and find the perfect role for you."
    end

    test "has navigation link to login page", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      assert lv
             |> element("a[href='/users/log_in']")
             |> has_element?()
    end
  end

  describe "account type selection" do
    test "selecting employer account type moves to step two", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      html =
        lv
        |> element("a", "Sign up as employer")
        |> render_click()

      assert html =~ "Looking for great candidates?"
      assert html =~ "Join as Employer"
      assert html =~ "Create an account"
      assert html =~ "Email"
    end

    test "selecting job seeker account type moves to step two", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      html =
        lv
        |> element("a", "Sign up as medical personnel")
        |> render_click()

      assert html =~ "Looking for your next opportunity?"
      assert html =~ "Join as Job Seeker"
      assert html =~ "Create an account"
      assert html =~ "Email"
    end
  end

  describe "registration page - step two" do
    test "renders registration form for employer", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      html =
        lv
        |> element("a", "Sign up as employer")
        |> render_click()

      assert html =~ "Looking for great candidates?"
      assert html =~ "Join as Employer"
      assert html =~ "Create an account"
      assert html =~ "Email"
      assert html =~ "By creating an account, you agree to our"
      assert html =~ "Terms of Service"
      assert html =~ "Privacy Policy"
    end

    test "renders registration form for job seeker", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      html =
        lv
        |> element("a", "Sign up as medical personnel")
        |> render_click()

      assert html =~ "Looking for your next opportunity?"
      assert html =~ "Join as Job Seeker"
      assert html =~ "Create an account"
      assert html =~ "Email"
      assert html =~ "By creating an account, you agree to our"
      assert html =~ "Terms of Service"
      assert html =~ "Privacy Policy"
    end
  end

  describe "form validation" do
    test "validates email field is required", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      lv
      |> element("a", "Sign up as employer")
      |> render_click()

      html =
        lv
        |> form("#registration_form", user: %{email: ""})
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end

    test "validates email format", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      lv
      |> element("a", "Sign up as employer")
      |> render_click()

      html =
        lv
        |> form("#registration_form", user: %{email: "invalid-email"})
        |> render_change()

      assert html =~ "must have the @ sign and no spaces"
    end

    test "validates email uniqueness on submit", %{conn: conn} do
      existing_user = user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/users/register")

      lv
      |> element("a", "Sign up as employer")
      |> render_click()

      html =
        lv
        |> form("#registration_form", user: %{email: existing_user.email})
        |> render_submit()

      assert html =~ "has already been taken"
    end
  end

  describe "successful registration" do
    test "creates employer user and sends confirmation email", %{conn: conn} do
      email = unique_user_email()

      {:ok, lv, _html} = live(conn, ~p"/users/register")

      lv
      |> element("a", "Sign up as employer")
      |> render_click()

      {:ok, _lv, html} =
        lv
        |> form("#registration_form", user: %{email: email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log_in")

      assert html =~ "An email was sent to #{email}, please access it to confirm your account."

      user = BemedaPersonal.Repo.get_by(BemedaPersonal.Accounts.User, email: email)
      assert user
      assert user.user_type == :employer
      assert user.locale == :en
    end

    test "creates job seeker user and sends confirmation email", %{conn: conn} do
      email = unique_user_email()

      {:ok, lv, _html} = live(conn, ~p"/users/register")

      lv
      |> element("a", "Sign up as medical personnel")
      |> render_click()

      {:ok, _lv, html} =
        lv
        |> form("#registration_form", user: %{email: email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log_in")

      assert html =~ "An email was sent to #{email}, please access it to confirm your account."

      user = BemedaPersonal.Repo.get_by(BemedaPersonal.Accounts.User, email: email)
      assert user
      assert user.user_type == :job_seeker
      assert user.locale == :en
    end

    test "creates login token for new user", %{conn: conn} do
      email = unique_user_email()

      {:ok, lv, _html} = live(conn, ~p"/users/register")

      lv
      |> element("a", "Sign up as employer")
      |> render_click()

      lv
      |> form("#registration_form", user: %{email: email})
      |> render_submit()

      user = BemedaPersonal.Repo.get_by(BemedaPersonal.Accounts.User, email: email)
      token = BemedaPersonal.Repo.get_by(BemedaPersonal.Accounts.UserToken, user_id: user.id)

      assert token
      assert token.context == "login"
    end
  end

  describe "registration errors" do
    test "handles registration errors gracefully", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      lv
      |> element("a", "Sign up as employer")
      |> render_click()

      html =
        lv
        |> form("#registration_form", user: %{email: "invalid email with spaces"})
        |> render_submit()

      assert html =~ "must have the @ sign and no spaces"
      refute html =~ "An email was sent"
    end
  end

  describe "navigation" do
    test "login link navigates to login page from step one", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      {:ok, _login_live, login_html} =
        lv
        |> element("a", "Sign in")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/log_in")

      assert login_html =~ "Log in"
    end
  end

  describe "form focus" do
    test "email input receives focus when step two loads", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      lv
      |> element("a", "Sign up as employer")
      |> render_click()

      assert lv
             |> element("input[name='user[email]'][phx-mounted]")
             |> has_element?()
    end
  end

  describe "form submission button state" do
    test "submit button shows loading state during submission", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      lv
      |> element("a", "Sign up as employer")
      |> render_click()

      assert lv
             |> element("button[phx-disable-with='Creating account...']")
             |> has_element?()
    end
  end
end
