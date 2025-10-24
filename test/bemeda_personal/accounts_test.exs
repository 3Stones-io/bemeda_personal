defmodule BemedaPersonal.AccountsTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.TestUtils, only: [drain_existing_emails: 0]

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Accounts.UserToken

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end

    test "does not return soft deleted users" do
      user = user_fixture()
      assert Accounts.get_user_by_email(user.email)
      {:ok, _deleted_user} = Accounts.soft_delete_user(user)
      refute Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = set_password(user_fixture())
      refute Accounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = set_password(user_fixture())

      assert %User{id: ^id} =
               Accounts.get_user_by_email_and_password(user.email, valid_user_password())
    end

    test "does not return soft deleted users" do
      user = set_password(user_fixture())
      assert Accounts.get_user_by_email_and_password(user.email, valid_user_password())
      {:ok, _deleted_user} = Accounts.soft_delete_user(user)
      refute Accounts.get_user_by_email_and_password(user.email, valid_user_password())
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

    test "raises for soft deleted users" do
      user = user_fixture()
      assert Accounts.get_user!(user.id)
      {:ok, _deleted_user} = Accounts.soft_delete_user(user)

      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(user.id)
      end
    end
  end

  describe "register_user/1" do
    test "requires email to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{email: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates email when given" do
      {:error, changeset} = Accounts.register_user(%{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum values for email for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{email: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness" do
      %{email: email} = user_fixture()
      {:error, changeset} = Accounts.register_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      {:error, upper_changeset} = Accounts.register_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(upper_changeset).email
    end

    test "registers users without password" do
      email = unique_user_email()

      {:ok, user} =
        %{email: email}
        |> valid_user_attributes()
        |> Accounts.register_user()

      assert user.email == email

      refute user.hashed_password
      refute user.confirmed_at
      refute user.password
    end
  end

  describe "invite_user/2" do
    test "creates user and company, sends login instructions" do
      email = unique_user_email()

      attrs = %{
        "email" => email,
        "first_name" => "John",
        "last_name" => "Doe",
        "locale" => "en",
        "user_type" => "employer",
        "registration_source" => "invited",
        "company" => %{
          "name" => "Test Company Inc"
        }
      }

      {:ok, user} = Accounts.invite_user(attrs, fn _token -> "http://test.com" end)

      assert user.email == email
      assert user.first_name == "John"
      assert user.last_name == "Doe"
      assert user.user_type == :employer
      assert user.registration_source == :invited
      refute user.hashed_password
      refute user.confirmed_at

      company = BemedaPersonal.Companies.get_company_by_user(user)
      assert company.name == "Test Company Inc"
      assert company.admin_user_id == user.id

      assert_received {:email, email_struct}
      assert [{_name, ^email}] = email_struct.to
      assert email_struct.subject =~ "Invitation"
    end

    test "returns error when user data is invalid" do
      attrs = %{
        "email" => "invalid",
        "company" => %{"name" => "Test Company"}
      }

      {:error, changeset} =
        Accounts.invite_user(attrs, fn _token -> "http://test.com" end)

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)

      assert Repo.aggregate(BemedaPersonal.Accounts.User, :count) == 0
      assert Repo.aggregate(BemedaPersonal.Companies.Company, :count) == 0
    end

    test "returns error when company data is invalid" do
      email = unique_user_email()

      attrs = %{
        "email" => email,
        "first_name" => "John",
        "last_name" => "Doe",
        "user_type" => "employer",
        "registration_source" => "invited",
        "company" => %{}
      }

      {:error, changeset} =
        Accounts.invite_user(attrs, fn _token -> "http://test.com" end)

      assert %{name: ["can't be blank"]} = errors_on(changeset)

      refute Accounts.get_user_by_email(email)
      assert Repo.aggregate(BemedaPersonal.Companies.Company, :count) == 0
    end

    test "transaction completes even if email fails (email is not critical)" do
      email = unique_user_email()

      attrs = %{
        "email" => email,
        "first_name" => "John",
        "last_name" => "Doe",
        "user_type" => "employer",
        "registration_source" => "invited",
        "company" => %{"name" => "Test Company"}
      }

      {:ok, user} = Accounts.invite_user(attrs, fn _token -> "http://test.com" end)

      assert user.email == email
      assert Accounts.get_user_by_email(email)
      company = BemedaPersonal.Companies.get_company_by_user(user)
      assert company
    end
  end

  describe "sudo_mode?/2" do
    test "validates the authenticated_at time" do
      now = DateTime.utc_now()

      assert Accounts.sudo_mode?(%User{authenticated_at: DateTime.utc_now()})
      assert Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -19, :minute)})
      refute Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -21, :minute)})

      # minute override
      refute Accounts.sudo_mode?(
               %User{authenticated_at: DateTime.add(now, -11, :minute)},
               -10
             )

      # not authenticated
      refute Accounts.sudo_mode?(%User{})
    end
  end

  describe "change_user_email/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "deliver_user_update_email_instructions/3" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      encoded_token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(user, "current@example.com", url)
        end)

      {:ok, decoded_token} = Base.url_decode64(encoded_token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, decoded_token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup do
      user = unconfirmed_user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{user: user, token: token, email: email}
    end

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      assert {:ok, %{email: ^email}} = Accounts.update_user_email(user, token)
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user} do
      assert Accounts.update_user_email(user, "oops") ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      assert Accounts.update_user_email(%{user | email: "current@example.com"}, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])

      assert Accounts.update_user_email(user, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "update_user_locale/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates locale", %{user: user} do
      {:error, changeset} = Accounts.update_user_locale(user, %{locale: "invalid"})
      assert "is invalid" in errors_on(changeset).locale
    end

    test "updates the locale", %{user: user} do
      {:ok, updated_user} = Accounts.update_user_locale(user, %{locale: "fr"})
      assert updated_user.locale == :fr
    end
  end

  describe "has_password?/1" do
    test "returns true for user with password" do
      user = user_fixture()
      user_with_password = set_password(user)

      assert Accounts.has_password?(user_with_password)
    end

    test "returns false for user without password" do
      user = user_fixture()
      refute Accounts.has_password?(user)
    end

    test "returns false for new user struct" do
      refute Accounts.has_password?(%User{})
    end
  end

  describe "change_user_password/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_user_password(
          %User{},
          %{
            "password" => "new password"
          },
          hash_password: false
        )

      assert changeset.valid?
      assert get_change(changeset, :password) == "new password"
      assert is_nil(get_change(changeset, :hashed_password))
    end

    test "includes current_password validation for users with password" do
      user = user_fixture()
      user_with_password = set_password(user)

      changeset =
        user_with_password
        |> Accounts.change_user_password(%{
          "current_password" => "wrong password",
          "password" => "new password"
        })
        |> Map.put(:action, :validate)

      refute changeset.valid?
      assert "is not valid" in errors_on(changeset).current_password
    end

    test "does not require current_password for users without password" do
      user = user_fixture()

      changeset =
        Accounts.change_user_password(
          user,
          %{
            "password" => "new password"
          },
          hash_password: false
        )

      assert changeset.valid?
    end
  end

  describe "update_user_password/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, %{
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
        Accounts.update_user_password(user, %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      drain_existing_emails()

      {:ok, {user, expired_tokens}} =
        Accounts.update_user_password(user, %{
          password: "new password"
        })

      assert expired_tokens == []
      refute user.password
      assert Accounts.get_user_by_email_and_password(user.email, "new password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _token = Accounts.generate_user_session_token(user)

      {:ok, {_token, _expired_tokens}} =
        Accounts.update_user_password(user, %{
          password: "new password"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
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
      assert user_token.authenticated_at != nil

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session"
        })
      end
    end

    test "duplicates the authenticated_at of given user in new token", %{user: user} do
      past_time =
        :second
        |> DateTime.utc_now()
        |> DateTime.add(-3600)

      user = %{user | authenticated_at: past_time}
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.authenticated_at == user.authenticated_at
      assert DateTime.compare(user_token.inserted_at, user.authenticated_at) == :gt
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert {session_user, token_inserted_at} = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
      assert session_user.authenticated_at
      assert token_inserted_at != nil
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      dt = ~N[2020-01-01 00:00:00]
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: dt, authenticated_at: dt])
      refute Accounts.get_user_by_session_token(token)
    end

    test "does not return soft deleted users", %{user: user, token: token} do
      assert Accounts.get_user_by_session_token(token)
      {:ok, _deleted_user} = Accounts.soft_delete_user(user)
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "get_user_by_magic_link_token/1" do
    setup do
      user = user_fixture()
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)
      %{user: user, token: encoded_token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_magic_link_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_magic_link_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_magic_link_token(token)
    end

    test "does not return soft deleted users", %{user: user, token: token} do
      assert Accounts.get_user_by_magic_link_token(token)
      {:ok, _deleted_user} = Accounts.soft_delete_user(user)
      refute Accounts.get_user_by_magic_link_token(token)
    end
  end

  describe "login_user_by_magic_link/1" do
    test "confirms user and expires tokens" do
      user = unconfirmed_user_fixture()
      refute user.confirmed_at
      {encoded_token, hashed_token} = generate_user_magic_link_token(user)

      assert {:ok, {user, [%{token: ^hashed_token}]}} =
               Accounts.login_user_by_magic_link(encoded_token)

      assert user.confirmed_at
    end

    test "returns user and (deleted) token for confirmed user" do
      user = user_fixture()
      assert user.confirmed_at
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)
      assert {:ok, {logged_in_user, []}} = Accounts.login_user_by_magic_link(encoded_token)
      assert logged_in_user.id == user.id
      assert logged_in_user.email == user.email
      # one time use only
      assert {:error, :not_found} = Accounts.login_user_by_magic_link(encoded_token)
    end

    test "raises when unconfirmed user has password set" do
      user = unconfirmed_user_fixture()
      {1, nil} = Repo.update_all(User, set: [hashed_password: "hashed"])
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)

      assert_raise RuntimeError, ~r/magic link log in is not allowed/, fn ->
        Accounts.login_user_by_magic_link(encoded_token)
      end
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

  describe "deliver_login_instructions/2" do
    setup do
      %{user: unconfirmed_user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      encoded_token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      {:ok, decoded_token} = Base.url_decode64(encoded_token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, decoded_token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "login"
    end
  end

  describe "change_user_registration/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_registration(%User{})
      assert :email in changeset.required
      assert :first_name in changeset.required
      assert :last_name in changeset.required
    end

    test "allows setting fields" do
      changeset =
        Accounts.change_user_registration(
          %User{},
          %{email: "test@example.com", first_name: "John", last_name: "Doe"},
          validate_unique: false
        )

      assert changeset.changes.email == "test@example.com"
      assert changeset.changes.first_name == "John"
      assert changeset.changes.last_name == "Doe"
    end

    test "validates email format" do
      changeset =
        %User{}
        |> Accounts.change_user_registration(%{email: "invalid"}, [])
        |> Map.put(:action, :validate)

      refute changeset.valid?
      assert "must have the @ sign and no spaces" in errors_on(changeset).email
    end
  end

  describe "change_user_profile/2" do
    test "returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_profile(user)
      assert :medical_role in changeset.required
      assert :employment_type in changeset.required
      assert :location in changeset.required
      assert :bio in changeset.required
    end

    test "allows setting profile fields" do
      user = unconfirmed_user_fixture()

      changeset =
        Accounts.change_user_profile(user, %{
          medical_role: "Physiotherapist",
          employment_type: ["Full-time Hire"],
          location: "Zurich",
          bio: "Experienced professional"
        })

      assert changeset.changes.medical_role == :Physiotherapist
      assert changeset.changes.employment_type == [:"Full-time Hire"]
      assert changeset.changes.location == :Zurich
      assert changeset.changes.bio == "Experienced professional"
    end
  end

  describe "change_user_employment_type/2" do
    test "returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_employment_type(user)
      assert :employment_type in changeset.required
    end

    test "allows setting employment type" do
      user = user_fixture()

      changeset =
        Accounts.change_user_employment_type(user, %{employment_type: ["Contract Hire"]})

      assert changeset.changes.employment_type == [:"Contract Hire"]
    end
  end

  describe "change_user_medical_role/2" do
    test "returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_medical_role(user)
      assert :medical_role in changeset.required
      assert :location in changeset.required
      assert :phone in changeset.required
    end

    test "allows setting medical role" do
      user = unconfirmed_user_fixture()

      changeset =
        Accounts.change_user_medical_role(user, %{
          medical_role: "Physiotherapist",
          location: "Zurich",
          phone: "+41791234567"
        })

      assert changeset.changes.medical_role == :Physiotherapist
      assert changeset.changes.location == :Zurich
      assert changeset.changes.phone == "+41791234567"
    end
  end

  describe "change_user_bio/2" do
    test "returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user_bio(user)
    end

    test "allows setting bio" do
      user = user_fixture()
      bio = "Experienced medical professional"
      changeset = Accounts.change_user_bio(user, %{bio: bio})

      assert changeset.changes.bio == bio
    end
  end

  describe "update_user_profile/3" do
    test "updates user profile with valid data" do
      user = user_fixture()

      attrs = %{
        medical_role: "Physiotherapist",
        employment_type: ["Full-time Hire"],
        location: "Zurich",
        bio: "Experienced healthcare professional"
      }

      assert {:ok, updated_user} =
               Accounts.update_user_profile(user, &Accounts.change_user_profile/2, attrs)

      assert updated_user.medical_role == :Physiotherapist
      assert updated_user.employment_type == [:"Full-time Hire"]
      assert updated_user.location == :Zurich
      assert updated_user.bio == "Experienced healthcare professional"
    end

    test "returns error with invalid data" do
      user = user_fixture()
      attrs = %{medical_role: "invalid_role"}

      assert {:error, %Ecto.Changeset{}} =
               Accounts.update_user_profile(user, &Accounts.change_user_profile/2, attrs)
    end

    test "updates employment type" do
      user = user_fixture()
      attrs = %{employment_type: ["Contract Hire"]}

      assert {:ok, updated_user} =
               Accounts.update_user_profile(
                 user,
                 &Accounts.change_user_employment_type/2,
                 attrs
               )

      assert updated_user.employment_type == [:"Contract Hire"]
    end

    test "updates medical role" do
      user = user_fixture()

      attrs = %{
        medical_role: "Anesthesiologist",
        location: "Bern",
        phone: "+41791234567"
      }

      assert {:ok, updated_user} =
               Accounts.update_user_profile(user, &Accounts.change_user_medical_role/2, attrs)

      assert updated_user.medical_role == :Anesthesiologist
      assert updated_user.location == :Bern
      assert updated_user.phone == "+41791234567"
    end

    test "updates bio" do
      user = user_fixture()
      bio = "Experienced healthcare professional with 10 years in the field"
      attrs = %{bio: bio}

      assert {:ok, updated_user} =
               Accounts.update_user_profile(user, &Accounts.change_user_bio/2, attrs)

      assert updated_user.bio == bio
    end

    test "handles media asset upload" do
      user = user_fixture()

      attrs = %{
        "medical_role" => "Physiotherapist",
        "employment_type" => ["Full-time Hire"],
        "location" => "Zurich",
        "bio" => "Experienced healthcare professional with 10 years in the field",
        "media_data" => %{
          "file_name" => "profile.jpg",
          "type" => "image/jpeg",
          "upload_id" => "550e8400-e29b-41d4-a716-446655440000"
        }
      }

      assert {:ok, updated_user} =
               Accounts.update_user_profile(user, &Accounts.change_user_profile/2, attrs)

      assert updated_user.medical_role == :Physiotherapist
      assert updated_user.bio == "Experienced healthcare professional with 10 years in the field"
      updated_user = Repo.preload(updated_user, [:media_asset], force: true)

      if updated_user.media_asset do
        assert updated_user.media_asset.file_name == "profile.jpg"
        assert updated_user.media_asset.type == "image/jpeg"
      end
    end
  end

  describe "change_account_information/3" do
    test "returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = changeset = Accounts.change_account_information(user)
      assert :email in changeset.required
      assert :first_name in changeset.required
      assert :last_name in changeset.required
    end

    test "allows setting account information fields" do
      user = user_fixture()

      changeset =
        Accounts.change_account_information(user, %{
          email: "newemail@example.com",
          first_name: "Jane",
          last_name: "Smith",
          phone: "+41791234567"
        })

      assert changeset.changes.email == "newemail@example.com"
      assert changeset.changes.first_name == "Jane"
      assert changeset.changes.last_name == "Smith"
      assert changeset.changes.phone == "+41791234567"
    end

    test "does not require email to change" do
      user = user_fixture()

      changeset =
        Accounts.change_account_information(user, %{
          email: user.email,
          first_name: "Jane"
        })

      assert changeset.valid?
      assert changeset.changes.first_name == "Jane"
      refute Keyword.has_key?(changeset.errors, :email)
    end

    test "validates uniqueness only when email changes" do
      existing_user = user_fixture()
      user = user_fixture()

      changeset =
        user
        |> Accounts.change_account_information(%{email: existing_user.email})
        |> Map.put(:action, :validate)

      refute changeset.valid?
      assert "has already been taken" in errors_on(changeset).email
    end
  end

  describe "update_account_information/3" do
    test "updates account fields without changing email" do
      user = user_fixture()

      attrs = %{
        "email" => user.email,
        "first_name" => "UpdatedFirst",
        "last_name" => "UpdatedLast",
        "phone" => "+41791234567"
      }

      assert {:ok, updated_user} = Accounts.update_account_information(user, attrs)
      assert updated_user.first_name == "UpdatedFirst"
      assert updated_user.last_name == "UpdatedLast"
      assert updated_user.phone == "+41791234567"
      assert updated_user.email == user.email
    end

    test "updates account fields and sends email confirmation when email changes" do
      user = user_fixture()
      drain_existing_emails()
      new_email = unique_user_email()

      attrs = %{
        "email" => new_email,
        "first_name" => "UpdatedFirst",
        "last_name" => "UpdatedLast"
      }

      email_update_url_fun = fn _token -> "http://test.com/confirm" end

      assert {:ok, updated_user, :email_update_sent} =
               Accounts.update_account_information(user, attrs, email_update_url_fun)

      assert updated_user.first_name == "UpdatedFirst"
      assert updated_user.last_name == "UpdatedLast"
      assert updated_user.email == user.email

      assert_received {:email, email_struct}

      sent_to_email =
        email_struct.to
        |> List.first()
        |> elem(1)

      assert sent_to_email == new_email
      assert email_struct.subject =~ "Email Address Update"
    end

    test "updates account fields without sending email when email changes but no url function provided" do
      user = user_fixture()
      drain_existing_emails()
      new_email = unique_user_email()

      attrs = %{
        "email" => new_email,
        "first_name" => "UpdatedFirst",
        "last_name" => "UpdatedLast"
      }

      assert {:ok, updated_user} =
               Accounts.update_account_information(user, attrs, nil)

      assert updated_user.first_name == "UpdatedFirst"
      assert updated_user.last_name == "UpdatedLast"
      assert updated_user.email == user.email

      refute_received {:email, _}
    end

    test "returns error with invalid data" do
      user = user_fixture()

      attrs = %{
        "email" => "invalid-email",
        "first_name" => "UpdatedFirst"
      }

      assert {:error, %Ecto.Changeset{}} = Accounts.update_account_information(user, attrs)

      reloaded_user = Accounts.get_user!(user.id)
      assert reloaded_user.first_name == user.first_name
    end

    test "returns error when email is already taken" do
      existing_user = user_fixture()
      user = user_fixture()

      attrs = %{
        "email" => existing_user.email,
        "first_name" => "UpdatedFirst"
      }

      assert {:error, changeset} = Accounts.update_account_information(user, attrs)
      assert "has already been taken" in errors_on(changeset).email

      reloaded_user = Accounts.get_user!(user.id)
      assert reloaded_user.first_name == user.first_name
    end

    test "updates job seeker specific fields" do
      user = user_fixture(%{user_type: :job_seeker})

      attrs = %{
        "email" => user.email,
        "first_name" => "UpdatedFirst",
        "last_name" => "UpdatedLast",
        "date_of_birth" => "1990-05-15",
        "gender" => "male",
        "location" => "Zurich",
        "phone" => "+41791234567"
      }

      assert {:ok, updated_user} = Accounts.update_account_information(user, attrs)
      assert updated_user.first_name == "UpdatedFirst"
      assert updated_user.last_name == "UpdatedLast"
      assert updated_user.date_of_birth == ~D[1990-05-15]
      assert updated_user.gender == :male
      assert updated_user.location == :Zurich
      assert updated_user.phone == "+41791234567"
    end

    test "handles atom key attrs for email change" do
      user = user_fixture()
      drain_existing_emails()
      new_email = unique_user_email()

      attrs = %{
        email: new_email,
        first_name: "UpdatedFirst",
        last_name: "UpdatedLast"
      }

      email_update_url_fun = fn _token -> "http://test.com/confirm" end

      assert {:ok, updated_user, :email_update_sent} =
               Accounts.update_account_information(user, attrs, email_update_url_fun)

      assert updated_user.first_name == "UpdatedFirst"
      assert updated_user.email == user.email

      assert_received {:email, email_struct}

      sent_to_email =
        email_struct.to
        |> List.first()
        |> elem(1)

      assert sent_to_email == new_email
    end
  end

  describe "soft_delete_user/1" do
    setup do
      %{user: user_fixture()}
    end

    test "soft deletes a user by setting deleted_at", %{user: user} do
      assert is_nil(user.deleted_at)
      assert {:ok, deleted_user} = Accounts.soft_delete_user(user)
      assert deleted_user.deleted_at != nil
      assert DateTime.diff(DateTime.utc_now(), deleted_user.deleted_at, :second) < 5
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
