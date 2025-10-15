defmodule BemedaPersonalWeb.UserLive.RegistrationTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import Phoenix.LiveViewTest

  describe "Registration page" do
    test "renders registration page with account type selection", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Join as a job seeker or employer"
      assert html =~ "Sign up as employer"
      assert html =~ "Sign up as medical personnel"
      assert html =~ "Already have an account?"
      assert html =~ "Sign in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/register")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end

    test "allows selecting employer account type", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      html =
        lv
        |> element("a", "Sign up as employer")
        |> render_click()

      assert html =~ "Get connected with qualified healthcare professionals"
      assert html =~ "Work Email Address"
      assert html =~ "Create my account"
    end

    test "allows selecting job seeker account type", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      html =
        lv
        |> element("a", "Sign up as medical personnel")
        |> render_click()

      assert html =~ "Your bridge to the right healthcare opportunities in Switzerland"
      assert html =~ "Email address"
      assert html =~ "Create my account"
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      lv
      |> element("a", "Sign up as employer")
      |> render_click()

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "with spaces"})

      assert result =~ "must have the @ sign and no spaces"
    end

    test "submit button is disabled when terms not accepted", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      lv
      |> element("a", "Sign up as employer")
      |> render_click()

      html = render(lv)
      assert html =~ "disabled"
      assert html =~ "I agree with Bemeda Personal"
    end
  end

  describe "register user" do
    test "creates employer account and sends confirmation email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      lv
      |> element("a", "Sign up as employer")
      |> render_click()

      lv
      |> element("#registration_form")
      |> render_change(%{user: %{terms_accepted: "true"}})

      email = unique_user_email()

      html =
        lv
        |> form("#registration_form",
          user: %{
            first_name: "John",
            last_name: "Doe",
            email: email,
            terms_accepted: "true"
          }
        )
        |> render_submit()

      assert html =~ "You&#39;ve got mail!"
      assert html =~ "We just sent you an activation link"
      assert html =~ email
    end

    test "creates job seeker account and sends confirmation email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      lv
      |> element("a", "Sign up as medical personnel")
      |> render_click()

      lv
      |> element("#registration_form")
      |> render_change(%{user: %{terms_accepted: "true"}})

      email = unique_user_email()

      html =
        lv
        |> form("#registration_form",
          user: %{
            first_name: "Jane",
            last_name: "Smith",
            email: email,
            terms_accepted: "true"
          }
        )
        |> render_submit()

      assert html =~ "You&#39;ve got mail!"
      assert html =~ "We just sent you an activation link"
      assert html =~ email
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      user = user_fixture(%{email: "test@email.com"})

      lv
      |> element("a", "Sign up as employer")
      |> render_click()

      lv
      |> element("#registration_form")
      |> render_change(%{user: %{terms_accepted: "true"}})

      result =
        lv
        |> form("#registration_form",
          user: %{
            first_name: "Test",
            last_name: "User",
            email: user.email,
            terms_accepted: "true"
          }
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end

    test "validates required fields", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      lv
      |> element("a", "Sign up as employer")
      |> render_click()

      lv
      |> element("#registration_form")
      |> render_change(%{user: %{terms_accepted: "true"}})

      result =
        lv
        |> form("#registration_form",
          user: %{
            first_name: "",
            last_name: "",
            email: "",
            terms_accepted: "true"
          }
        )
        |> render_submit()

      assert result =~ "can&#39;t be blank"
    end
  end

  describe "job seeker profile completion flow" do
    test "job seeker with incomplete profile is redirected to profile completion", %{conn: conn} do
      user = unconfirmed_user_fixture(%{user_type: :job_seeker})

      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/users/profile"}}} = live(conn, ~p"/jobs")
    end

    test "employer without company is redirected to company creation", %{conn: conn} do
      user = unconfirmed_user_fixture(%{user_type: :employer})

      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/company/new"}}} = live(conn, ~p"/company")
    end

    test "job seeker with complete profile can access jobs page", %{conn: conn} do
      user = user_fixture(%{user_type: :job_seeker})

      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/jobs")

      assert html =~ "Browse Jobs"
      refute html =~ "lets get you started"
    end
  end

  describe "profile completion page" do
    test "redirects to first step automatically", %{conn: conn} do
      user = unconfirmed_user_fixture(%{user_type: :job_seeker})

      conn = log_in_user(conn, user)

      {:ok, _lv, _html} = live(conn, ~p"/users/profile")

      assert_receive {_ref,
                      {:redirect, _id, %{kind: :push, to: "/users/profile/employment_type"}}},
                     2000
    end

    test "displays employment type step", %{conn: conn} do
      user = unconfirmed_user_fixture(%{user_type: :job_seeker})

      conn = log_in_user(conn, user)

      {:ok, lv, _html} = live(conn, ~p"/users/profile/employment_type")

      html = render(lv)
      assert html =~ "Hi"
      assert html =~ user.first_name
      assert html =~ "lets get you started"
      assert html =~ "Step 1/3"
    end

    test "displays medical role step", %{conn: conn} do
      user = unconfirmed_user_fixture(%{user_type: :job_seeker})

      conn = log_in_user(conn, user)

      {:ok, lv, _html} = live(conn, ~p"/users/profile/medical_role")

      assert render(lv) =~ "Step 2/3"
    end

    test "displays bio step", %{conn: conn} do
      user = unconfirmed_user_fixture(%{user_type: :job_seeker})

      conn = log_in_user(conn, user)

      {:ok, lv, _html} = live(conn, ~p"/users/profile/bio")

      assert render(lv) =~ "Step 3/3"
    end
  end

  describe "registration navigation" do
    test "has link to login page", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      assert has_element?(lv, "a[href='/users/log_in']", "Sign in")
    end
  end
end
