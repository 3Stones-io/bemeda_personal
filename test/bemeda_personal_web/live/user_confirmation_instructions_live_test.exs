defmodule BemedaPersonalWeb.UserConfirmationInstructionsLiveTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Repo

  setup do
    %{user: user_fixture()}
  end

  describe "Resend confirmation" do
    test "renders the resend confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/confirm")
      assert html =~ "Resend confirmation instructions"
    end

    test "sends a new confirmation token", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/confirm")

      # Submit the form
      lv
      |> form("#resend_confirmation_form", user: %{email: user.email})
      |> render_submit()

      # The main behavior we care about is that a token was created
      assert Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "confirm"
    end

    test "does not send confirmation token if user is confirmed", %{conn: conn, user: user} do
      user
      |> Accounts.User.confirm_changeset()
      |> Repo.update!()

      {:ok, lv, _html} = live(conn, ~p"/users/confirm")

      # Submit the form
      lv
      |> form("#resend_confirmation_form", user: %{email: user.email})
      |> render_submit()

      # The main behavior we care about is that no token was created
      refute Repo.get_by(Accounts.UserToken, user_id: user.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/confirm")

      # Submit the form with an unknown email
      lv
      |> form("#resend_confirmation_form", user: %{email: "unknown@example.com"})
      |> render_submit()

      # The main behavior we care about is that no token was created for unknown email
      # Only check tokens in the test database (async tests may have other users' tokens)
      unknown_email_tokens =
        Accounts.UserToken
        |> Repo.all()
        |> Enum.filter(fn t -> t.sent_to == "unknown@example.com" end)

      assert unknown_email_tokens == []
    end
  end
end
