defmodule BemedaPersonal.Accounts.MagicLinkTokenTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures

  alias BemedaPersonal.Accounts.MagicLinkToken
  alias BemedaPersonal.Repo

  describe "build_magic_link_token/2" do
    test "creates magic link token with default context" do
      user = user_fixture()

      token = MagicLinkToken.build_magic_link_token(user)

      assert %MagicLinkToken{} = token
      assert token.user_id == user.id
      assert token.sent_to == user.email
      assert token.context == "magic_link"
      assert is_binary(token.token)
      assert byte_size(token.token) == 32
      assert is_nil(token.used_at)
    end

    test "creates magic link token with custom context" do
      user = user_fixture()

      token = MagicLinkToken.build_magic_link_token(user, "login")

      assert %MagicLinkToken{} = token
      assert token.user_id == user.id
      assert token.sent_to == user.email
      assert token.context == "login"
      assert is_binary(token.token)
      assert byte_size(token.token) == 32
      assert is_nil(token.used_at)
    end

    test "creates magic link token with atom context" do
      user = user_fixture()

      token = MagicLinkToken.build_magic_link_token(user, :sudo)

      assert %MagicLinkToken{} = token
      assert token.context == "sudo"
    end

    test "generates unique tokens for different calls" do
      user = user_fixture()

      token1 = MagicLinkToken.build_magic_link_token(user)
      token2 = MagicLinkToken.build_magic_link_token(user)

      assert token1.token != token2.token
    end
  end

  describe "verify_magic_link_token_query/2" do
    test "returns query for valid token verification" do
      user = user_fixture()
      token = MagicLinkToken.build_magic_link_token(user, "login")
      {:ok, saved_token} = Repo.insert(token)

      assert {:ok, query} =
               MagicLinkToken.verify_magic_link_token_query(saved_token.token, "login")

      assert %Ecto.Query{} = query

      # Execute the query to verify it works
      result = Repo.one(query)
      assert %MagicLinkToken{} = result
      assert result.id == saved_token.id
    end

    test "query excludes tokens with different context" do
      user = user_fixture()
      token = MagicLinkToken.build_magic_link_token(user, "login")
      {:ok, saved_token} = Repo.insert(token)

      assert {:ok, query} =
               MagicLinkToken.verify_magic_link_token_query(saved_token.token, "sudo")

      result = Repo.one(query)
      assert is_nil(result)
    end

    test "query excludes used tokens" do
      user = user_fixture()
      token = MagicLinkToken.build_magic_link_token(user, "login")
      {:ok, saved_token} = Repo.insert(token)

      # Mark token as used
      used_token = Ecto.Changeset.change(saved_token, used_at: DateTime.utc_now(:second))
      {:ok, _updated_token} = Repo.update(used_token)

      assert {:ok, query} =
               MagicLinkToken.verify_magic_link_token_query(saved_token.token, "login")

      result = Repo.one(query)
      assert is_nil(result)
    end

    test "query excludes expired tokens" do
      user = user_fixture()
      token = MagicLinkToken.build_magic_link_token(user, "login")

      # Insert token with old timestamp (expired)
      now = DateTime.utc_now(:second)
      expired_timestamp = DateTime.add(now, -20, :minute)
      expired_token = %{token | inserted_at: expired_timestamp}

      {:ok, saved_token} = Repo.insert(expired_token)

      assert {:ok, query} =
               MagicLinkToken.verify_magic_link_token_query(saved_token.token, "login")

      result = Repo.one(query)
      assert is_nil(result)
    end

    test "query excludes tokens with different token value" do
      user = user_fixture()
      token = MagicLinkToken.build_magic_link_token(user, "login")
      {:ok, _saved_token} = Repo.insert(token)

      different_token = :crypto.strong_rand_bytes(32)
      assert {:ok, query} = MagicLinkToken.verify_magic_link_token_query(different_token, "login")
      result = Repo.one(query)
      assert is_nil(result)
    end
  end

  describe "mark_as_used/1" do
    test "marks token as used successfully" do
      user = user_fixture()
      token = MagicLinkToken.build_magic_link_token(user, "login")
      {:ok, saved_token} = Repo.insert(token)

      assert is_nil(saved_token.used_at)

      assert {:ok, updated_token} = MagicLinkToken.mark_as_used(saved_token)
      assert %DateTime{} = updated_token.used_at
      assert updated_token.id == saved_token.id

      # Verify it's saved in database
      refreshed_token = Repo.get!(MagicLinkToken, saved_token.id)
      assert %DateTime{} = refreshed_token.used_at
    end

    test "preserves other token fields when marking as used" do
      user = user_fixture()
      token = MagicLinkToken.build_magic_link_token(user, "sudo")
      {:ok, saved_token} = Repo.insert(token)

      assert {:ok, updated_token} = MagicLinkToken.mark_as_used(saved_token)
      assert updated_token.token == saved_token.token
      assert updated_token.context == saved_token.context
      assert updated_token.sent_to == saved_token.sent_to
      assert updated_token.user_id == saved_token.user_id
    end

    test "can mark already used token as used again" do
      user = user_fixture()
      token = MagicLinkToken.build_magic_link_token(user, "login")
      {:ok, saved_token} = Repo.insert(token)

      # Mark as used first time
      assert {:ok, first_update} = MagicLinkToken.mark_as_used(saved_token)
      first_used_at = first_update.used_at

      # Mark as used second time
      assert {:ok, second_update} = MagicLinkToken.mark_as_used(first_update)
      assert %DateTime{} = second_update.used_at
      # Should have new timestamp
      assert DateTime.compare(second_update.used_at, first_used_at) in [:gt, :eq]
    end
  end

  describe "validity_in_minutes/1" do
    test "returns sudo validity for sudo context" do
      assert MagicLinkToken.validity_in_minutes("sudo") == 5
    end

    test "returns default validity for magic_link context" do
      assert MagicLinkToken.validity_in_minutes("magic_link") == 15
    end

    test "returns default validity for login context" do
      assert MagicLinkToken.validity_in_minutes("login") == 15
    end

    test "returns default validity for any other context" do
      assert MagicLinkToken.validity_in_minutes("custom") == 15
      assert MagicLinkToken.validity_in_minutes("reset") == 15
      assert MagicLinkToken.validity_in_minutes("") == 15
    end

    test "returns default validity for nil context" do
      assert MagicLinkToken.validity_in_minutes(nil) == 15
    end
  end

  describe "schema validations" do
    test "token can be inserted and retrieved" do
      user = user_fixture()
      token = MagicLinkToken.build_magic_link_token(user, "test")

      assert {:ok, saved_token} = Repo.insert(token)
      assert saved_token.id
      assert %DateTime{} = saved_token.inserted_at

      retrieved_token = Repo.get!(MagicLinkToken, saved_token.id)
      assert retrieved_token.token == token.token
      assert retrieved_token.context == token.context
      assert retrieved_token.sent_to == token.sent_to
    end

    test "token belongs to user association works" do
      user = user_fixture()
      token = MagicLinkToken.build_magic_link_token(user, "test")
      {:ok, saved_token} = Repo.insert(token)

      token_with_user =
        saved_token.id
        |> then(&Repo.get!(MagicLinkToken, &1))
        |> Repo.preload(:user)

      assert token_with_user.user.id == user.id
      assert token_with_user.user.email == user.email
    end
  end
end
