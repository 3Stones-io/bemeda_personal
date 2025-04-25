defmodule BemedaPersonalWeb.UserSettingsLiveTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user_fixture(confirmed: true))
        |> live(~p"/users/settings")

      assert html =~ "Change Email"
      assert html =~ "Change Password"
      assert html =~ "Update Name"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/users/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_user_password()
      user = user_fixture(%{confirmed: true, password: password})
      %{conn: log_in_user(conn, user), user: user, password: password}
    end

    test "updates the user email", %{conn: conn, password: password, user: user} do
      new_email = unique_user_email()

      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => password,
          "user" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Accounts.get_user_by_email(user.email)
    end

    test "form renders errors with invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "user" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "form cannot submit with invalid data", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => "invalid",
          "user" => %{"email" => user.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_user_password()
      user = user_fixture(%{confirmed: true, password: password})
      %{conn: log_in_user(conn, user), user: user, password: password}
    end

    test "updates the user password", %{conn: conn, user: user, password: password} do
      new_password = valid_user_password()

      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "user" => %{
            "email" => user.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/users/settings"

      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_user_by_email_and_password(user.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      user = user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{conn: log_in_user(conn, user), token: token, email: email, user: user}
    end

    test "updates the user email once", %{conn: conn, user: user, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/users/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Accounts.get_user_by_email(user.email)
      assert Accounts.get_user_by_email(email)

      # use confirm token again
      {:error, redirect_2} = live(conn, ~p"/users/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect_2
      assert path == ~p"/users/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, user: user} do
      {:error, redirect} = live(conn, ~p"/users/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Accounts.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/users/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end

  describe "update name form" do
    setup %{conn: conn} do
      user = user_fixture(%{confirmed: true})
      %{conn: log_in_user(conn, user), user: user}
    end

    test "updates the user name", %{conn: conn} do
      new_first_name = "New"
      new_last_name = "Name"

      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#name_form", %{
          "user" => %{"first_name" => new_first_name, "last_name" => new_last_name}
        })
        |> render_submit()

      assert result =~ "Name updated successfully"
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> element("#name_form")
        |> render_change(%{
          "user" => %{"first_name" => "", "last_name" => ""}
        })

      assert result =~ "Update Name"
      assert result =~ "can&#39;t be blank"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#name_form", %{
          "user" => %{"first_name" => "", "last_name" => ""}
        })
        |> render_submit()

      assert result =~ "Update Name"
      assert result =~ "can&#39;t be blank"
    end
  end

  describe "user rating display" do
    setup %{conn: conn} do
      user = user_fixture(%{confirmed: true})
      company = company_fixture(user_fixture())
      %{conn: log_in_user(conn, user), user: user, company: company}
    end

    test "displays rating component with no ratings", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/settings")

      # Check that rating section is displayed
      assert html =~ "Your Rating"
      assert html =~ "How companies have rated your applications"

      # Rating component should be rendered (no ratings yet)
      assert html =~ "<div class=\"star-rating flex\">"
      assert html =~ "hero-star"
    end

    test "displays user rating correctly when rated", %{conn: conn, user: user, company: company} do
      # Add a rating for the user
      BemedaPersonal.Ratings.create_rating(%{
        rater_type: "Company",
        rater_id: company.id,
        ratee_type: "User",
        ratee_id: user.id,
        score: 5,
        comment: "Great candidate!"
      })

      {:ok, _lv, html} = live(conn, ~p"/users/settings")

      # Verify rating is displayed
      assert html =~ "Your Rating"
      assert html =~ "5.0"

      # Should have 5 filled stars
      assert html =~ "fill-current"
    end

    test "displays partial rating correctly", %{conn: conn, user: user, company: company} do
      # Add a rating with partial stars
      BemedaPersonal.Ratings.create_rating(%{
        rater_type: "Company",
        rater_id: company.id,
        ratee_type: "User",
        ratee_id: user.id,
        score: 3,
        comment: "Average candidate"
      })

      {:ok, _lv, html} = live(conn, ~p"/users/settings")

      # Verify rating is displayed
      assert html =~ "Your Rating"
      assert html =~ "3.0"

      # Should have mix of filled and empty stars
      assert html =~ "fill-current"
      assert html =~ "text-gray-300"
    end
  end
end
