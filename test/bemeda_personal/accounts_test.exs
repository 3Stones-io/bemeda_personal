defmodule BemedaPersonal.AccountsTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import Swoosh.TestAssertions

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Accounts.UserToken

  describe "get_user_by_email/2" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email(nil, "unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(nil, user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture()
      refute Accounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture()

      assert %User{id: ^id} =
               Accounts.get_user_by_email_and_password(user.email, valid_user_password())
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!("11111111-1111-1111-1111-111111111111")
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Accounts.register_user(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = user_fixture()
      {:error, changeset} = Accounts.register_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset_2} = Accounts.register_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset_2).email
    end

    test "registers users with a hashed password" do
      email = unique_user_email()

      {:ok, user} =
        [email: email]
        |> valid_user_attributes()
        |> Accounts.register_user()

      assert user.email == email
      assert is_binary(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end
  end

  describe "change_user_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_registration(%User{})

      assert changeset.required == [
               :medical_role,
               :department,
               :city,
               :country,
               :street,
               :zip_code,
               :first_name,
               :last_name,
               :password,
               :email
             ]
    end

    test "allows fields to be set" do
      email = unique_user_email()
      password = valid_user_password()

      changeset =
        Accounts.change_user_registration(
          %User{},
          valid_user_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_user_email/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_user_email/3" do
    setup do
      %{user: user_fixture()}
    end

    test "requires email to change", %{user: user} do
      {:error, changeset} = Accounts.apply_user_email(user, valid_user_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{user: user} do
      {:error, changeset} =
        Accounts.apply_user_email(user, valid_user_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.apply_user_email(user, valid_user_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{user: user} do
      %{email: email} = user_fixture()
      password = valid_user_password()

      {:error, changeset} = Accounts.apply_user_email(user, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Accounts.apply_user_email(user, "invalid", %{email: unique_user_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{user: user} do
      email = unique_user_email()
      {:ok, user} = Accounts.apply_user_email(user, valid_user_password(), %{email: email})
      assert user.email == email
      assert Accounts.get_user!(user.id).email != email
    end
  end

  describe "deliver_user_update_email_instructions/3" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(user, "current@example.com", url)
        end)

      {:ok, decoded_token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, decoded_token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup do
      user = user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{user: user, token: token, email: email}
    end

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      assert Accounts.update_user_email(user, token) == :ok
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      assert changed_user.confirmed_at
      assert changed_user.confirmed_at != user.confirmed_at
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user} do
      assert Accounts.update_user_email(user, "oops") == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      assert Accounts.update_user_email(%{user | email: "current@example.com"}, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_user_email(user, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_user_password/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_user_password(%User{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/3" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, valid_user_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_user_password(user, valid_user_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, "invalid", %{password: valid_user_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{user: user} do
      {:ok, user} =
        Accounts.update_user_password(user, valid_user_password(), %{
          password: "new valid password"
        })

      assert is_nil(user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _token = Accounts.generate_user_session_token(user)

      {:ok, _user} =
        Accounts.update_user_password(user, valid_user_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_user_personal_info/2" do
    test "returns a user changeset for personal info" do
      user = user_fixture()
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_personal_info(user, %{})
      assert changeset.data == user
    end
  end

  describe "update_user_personal_info/2" do
    test "updates the user personal info with valid data" do
      user = user_fixture()

      update_attrs = %{
        city: "Portland",
        country: "USA",
        first_name: "Jane",
        gender: :female,
        last_name: "Smith",
        street: "456 Oak St",
        zip_code: "54321"
      }

      assert {:ok, updated_user} = Accounts.update_user_personal_info(user, update_attrs)
      assert updated_user.city == "Portland"
      assert updated_user.country == "USA"
      assert updated_user.first_name == "Jane"
      assert updated_user.gender == :female
      assert updated_user.last_name == "Smith"
      assert updated_user.street == "456 Oak St"
      assert updated_user.zip_code == "54321"
    end

    test "returns error changeset with invalid data" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user_personal_info(user, %{city: ""})
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "delete_user_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_user_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "deliver_user_confirmation_instructions/2" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, decoded_token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, decoded_token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "confirm"
    end
  end

  describe "confirm_user/1" do
    setup do
      user = user_fixture()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      %{user: user, token: token}
    end

    test "confirms the email with a valid token", %{user: user, token: token} do
      assert {:ok, confirmed_user} = Accounts.confirm_user(token)
      assert confirmed_user.confirmed_at
      assert confirmed_user.confirmed_at != user.confirmed_at
      assert Repo.get!(User, user.id).confirmed_at
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not confirm with invalid token", %{user: user} do
      assert Accounts.confirm_user("oops") == :error
      refute Repo.get!(User, user.id).confirmed_at
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not confirm email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.confirm_user(token) == :error
      refute Repo.get!(User, user.id).confirmed_at
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "deliver_user_reset_password_instructions/2" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      {:ok, decoded_token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, decoded_token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "reset_password"
    end
  end

  describe "get_user_by_reset_password_token/1" do
    setup do
      user = user_fixture()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      %{user: user, token: token}
    end

    test "returns the user with valid token", %{user: %{id: id}, token: token} do
      assert %User{id: ^id} = Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: id)
    end

    test "does not return the user with invalid token", %{user: user} do
      refute Accounts.get_user_by_reset_password_token("oops")
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not return the user if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "reset_user_password/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.reset_user_password(user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_user_password(user, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, updated_user} = Accounts.reset_user_password(user, %{password: "new valid password"})
      assert is_nil(updated_user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _token = Accounts.generate_user_session_token(user)
      {:ok, _user} = Accounts.reset_user_password(user, %{password: "new valid password"})
      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "update_user_locale/2" do
    test "with valid data updates the locale" do
      user = user_fixture()
      assert {:ok, updated_user} = Accounts.update_user_locale(user, %{locale: "de"})
      assert updated_user.locale == :de
    end

    test "with invalid locale returns error changeset" do
      user = user_fixture()
      assert {:error, changeset} = Accounts.update_user_locale(user, %{locale: "invalid"})
      assert "is invalid" in errors_on(changeset).locale
    end

    test "with empty locale uses default locale" do
      user = user_fixture()
      assert {:ok, updated_user} = Accounts.update_user_locale(user, %{locale: ""})
      assert updated_user.locale == :de
    end

    test "new users have default locale" do
      user = user_fixture()
      assert user.locale == :en
    end
  end

  describe "magic_link_preferences_changeset/2" do
    test "allows magic_link_enabled to be set" do
      user = user_fixture()
      changeset = User.magic_link_preferences_changeset(user, %{magic_link_enabled: true})

      assert changeset.valid?
      assert get_change(changeset, :magic_link_enabled) == true
    end

    test "validates passwordless_only requires magic_link_enabled" do
      user = user_fixture()

      changeset =
        User.magic_link_preferences_changeset(user, %{
          passwordless_only: true,
          magic_link_enabled: false
        })

      refute changeset.valid?

      assert %{passwordless_only: ["can only be enabled when magic links are enabled"]} =
               errors_on(changeset)
    end

    test "validates passwordless_only without magic_link_enabled" do
      user = user_fixture()

      changeset = User.magic_link_preferences_changeset(user, %{passwordless_only: true})

      refute changeset.valid?

      assert %{passwordless_only: ["can only be enabled when magic links are enabled"]} =
               errors_on(changeset)
    end

    test "allows passwordless_only when magic_link_enabled is true" do
      user = user_fixture()

      changeset =
        User.magic_link_preferences_changeset(user, %{
          passwordless_only: true,
          magic_link_enabled: true
        })

      assert changeset.valid?
    end

    test "allows passwordless_only when user already has magic_link_enabled" do
      # First enable magic links for the user
      user = user_fixture()

      {:ok, user_with_magic_links} =
        user
        |> User.magic_link_preferences_changeset(%{magic_link_enabled: true})
        |> Repo.update()

      changeset =
        User.magic_link_preferences_changeset(user_with_magic_links, %{passwordless_only: true})

      assert changeset.valid?
    end

    test "allows disabling passwordless_only" do
      user = user_fixture()
      changeset = User.magic_link_preferences_changeset(user, %{passwordless_only: false})

      assert changeset.valid?
      # When value doesn't change (false -> false), there's no change recorded
      refute get_change(changeset, :passwordless_only)
    end
  end

  describe "track_magic_link_sent/1" do
    test "updates last_magic_link_sent_at timestamp" do
      user = user_fixture()
      assert is_nil(user.last_magic_link_sent_at)

      assert {:ok, updated_user} = User.track_magic_link_sent(user)
      assert %DateTime{} = updated_user.last_magic_link_sent_at
    end

    test "increments magic_link_send_count" do
      user = user_fixture()
      assert user.magic_link_send_count == 0

      assert {:ok, updated_user} = User.track_magic_link_sent(user)
      assert updated_user.magic_link_send_count == 1

      assert {:ok, updated_user_2} = User.track_magic_link_sent(updated_user)
      assert updated_user_2.magic_link_send_count == 2
    end

    test "handles nil magic_link_send_count gracefully" do
      # Create user with nil count (edge case)
      user = user_fixture()
      user_with_nil_count = %{user | magic_link_send_count: nil}

      assert {:ok, updated_user} = User.track_magic_link_sent(user_with_nil_count)
      assert updated_user.magic_link_send_count == 1
    end

    test "persists changes to database" do
      user = user_fixture()
      assert {:ok, _updated_user} = User.track_magic_link_sent(user)

      # Verify changes are saved
      persisted_user = Accounts.get_user!(user.id)
      assert persisted_user.magic_link_send_count == 1
      assert %DateTime{} = persisted_user.last_magic_link_sent_at
    end
  end

  describe "record_sudo_authentication/1" do
    setup do
      %{user: user_fixture()}
    end

    test "successfully records sudo authentication timestamp", %{user: user} do
      # Verify user initially has no sudo timestamp
      assert is_nil(user.last_sudo_at)

      # Record sudo authentication
      assert {:ok, updated_user} = User.record_sudo_authentication(user)

      # Verify timestamp was set
      assert %DateTime{} = updated_user.last_sudo_at
      assert updated_user.id == user.id
    end

    test "persists sudo authentication timestamp to database", %{user: user} do
      # Record sudo authentication
      assert {:ok, updated_user} = User.record_sudo_authentication(user)

      # Verify changes are persisted in database
      persisted_user = Accounts.get_user!(user.id)
      assert %DateTime{} = persisted_user.last_sudo_at
      assert persisted_user.last_sudo_at == updated_user.last_sudo_at
    end

    test "updates existing sudo authentication timestamp", %{user: user} do
      # Record initial sudo authentication
      assert {:ok, first_update} = User.record_sudo_authentication(user)
      first_timestamp = first_update.last_sudo_at

      # Wait sufficient time to ensure different timestamps (seconds precision)
      :timer.sleep(1500)

      # Record another sudo authentication
      assert {:ok, second_update} = User.record_sudo_authentication(first_update)

      # Verify timestamp was updated (not just the first time)
      assert %DateTime{} = second_update.last_sudo_at
      assert DateTime.compare(second_update.last_sudo_at, first_timestamp) == :gt
    end

    test "returns {:ok, user} tuple structure", %{user: user} do
      result = User.record_sudo_authentication(user)

      assert {:ok, updated_user} = result
      assert %User{} = updated_user
      assert updated_user.id == user.id
    end
  end

  describe "magic links" do
    test "deliver_magic_link/2 creates token and sends email" do
      user = user_fixture(%{magic_link_enabled: true})

      assert {:ok, token} = Accounts.deliver_magic_link(user, &"http://example.com/#{&1}")
      assert token.user_id == user.id
      assert token.context == "magic_link"

      assert_email_sent(fn email ->
        {"Test User", user.email} in email.to
      end)
    end

    test "deliver_magic_link/2 fails for disabled magic links" do
      user = user_fixture(%{magic_link_enabled: false})

      # This should fail because magic links are disabled for this user
      assert {:error, :magic_links_disabled} =
               Accounts.deliver_magic_link(user, &"http://example.com/#{&1}")
    end

    test "verify_magic_link/1 returns user for valid token" do
      user = user_fixture(%{magic_link_enabled: true})
      {:ok, token} = Accounts.deliver_magic_link(user, &"http://example.com/#{&1}")

      encoded = Base.url_encode64(token.token, padding: false)
      assert {:ok, verified_user} = Accounts.verify_magic_link(encoded)
      assert verified_user.id == user.id
    end

    test "verify_magic_link/1 fails for expired token" do
      user = user_fixture(%{magic_link_enabled: true})
      {:ok, token} = Accounts.deliver_magic_link(user, &"http://example.com/#{&1}")

      # Manually expire the token
      expired =
        DateTime.utc_now()
        |> DateTime.add(-3600, :second)
        |> DateTime.truncate(:second)

      token
      |> Ecto.Changeset.change(inserted_at: expired)
      |> Repo.update!()

      encoded = Base.url_encode64(token.token, padding: false)
      assert {:error, :invalid_or_expired} = Accounts.verify_magic_link(encoded)
    end

    test "verify_magic_link/1 fails for used token" do
      user = user_fixture(%{magic_link_enabled: true})
      {:ok, token} = Accounts.deliver_magic_link(user, &"http://example.com/#{&1}")

      encoded = Base.url_encode64(token.token, padding: false)
      # Use the token once
      assert {:ok, _user} = Accounts.verify_magic_link(encoded)
      # Try to use it again
      assert {:error, :invalid_or_expired} = Accounts.verify_magic_link(encoded)
    end

    test "rate limits magic link requests" do
      user = user_fixture(%{magic_link_enabled: true})

      # First 3 should succeed
      assert {:ok, _token1} = Accounts.deliver_magic_link(user, &"http://example.com/#{&1}")
      assert {:ok, _token2} = Accounts.deliver_magic_link(user, &"http://example.com/#{&1}")
      assert {:ok, _token3} = Accounts.deliver_magic_link(user, &"http://example.com/#{&1}")

      # Fourth should fail
      assert {:error, :too_many_requests} =
               Accounts.deliver_magic_link(user, &"http://example.com/#{&1}")
    end
  end

  describe "sudo mode" do
    test "deliver_sudo_magic_link/2 creates token and sends email" do
      user = user_fixture()

      assert {:ok, token} = Accounts.deliver_sudo_magic_link(user, &"http://example.com/#{&1}")
      assert token.user_id == user.id
      assert token.context == "sudo"

      assert_email_sent(fn email ->
        {"Test User", user.email} in email.to
      end)
    end

    test "verify_sudo_token/1 returns user for valid token" do
      user = user_fixture()
      {:ok, token} = Accounts.deliver_sudo_magic_link(user, &"http://example.com/#{&1}")

      encoded = Base.url_encode64(token.token, padding: false)
      assert {:ok, verified_user} = Accounts.verify_sudo_token(encoded)
      assert verified_user.id == user.id
      assert %DateTime{} = verified_user.last_sudo_at
    end

    test "verify_sudo_token/1 fails for expired token" do
      user = user_fixture()
      {:ok, token} = Accounts.deliver_sudo_magic_link(user, &"http://example.com/#{&1}")

      # Manually expire the token (sudo tokens expire after 5 minutes)
      expired =
        DateTime.utc_now()
        |> DateTime.add(-360, :second)
        |> DateTime.truncate(:second)

      token
      |> Ecto.Changeset.change(inserted_at: expired)
      |> Repo.update!()

      encoded = Base.url_encode64(token.token, padding: false)
      assert {:error, :invalid_or_expired} = Accounts.verify_sudo_token(encoded)
    end

    test "has_recent_sudo?/1 returns false for user without sudo" do
      user = user_fixture()
      refute Accounts.has_recent_sudo?(user)
    end

    test "has_recent_sudo?/1 returns true for recent sudo" do
      user = user_fixture()
      {:ok, updated_user} = User.record_sudo_authentication(user)
      assert Accounts.has_recent_sudo?(updated_user)
    end

    test "has_recent_sudo?/1 returns false for expired sudo" do
      user = user_fixture()
      # Set last_sudo_at to 20 minutes ago (expired, since limit is 15 minutes)
      expired =
        DateTime.utc_now()
        |> DateTime.add(-1200, :second)
        |> DateTime.truncate(:second)

      user_with_old_sudo =
        user
        |> Ecto.Changeset.change(last_sudo_at: expired)
        |> Repo.update!()

      refute Accounts.has_recent_sudo?(user_with_old_sudo)
    end
  end

  describe "update_magic_link_preferences/2" do
    test "updates magic link preferences" do
      user = user_fixture()

      attrs = %{magic_link_enabled: true, passwordless_only: false}
      assert {:ok, updated_user} = Accounts.update_magic_link_preferences(user, attrs)
      assert updated_user.magic_link_enabled == true
      assert updated_user.passwordless_only == false
    end

    test "validates that passwordless_only requires magic_link_enabled" do
      user = user_fixture()

      attrs = %{magic_link_enabled: false, passwordless_only: true}
      assert {:error, changeset} = Accounts.update_magic_link_preferences(user, attrs)

      assert "can only be enabled when magic links are enabled" in errors_on(changeset).passwordless_only
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
