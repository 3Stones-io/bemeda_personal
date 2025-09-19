defmodule BemedaPersonal.Accounts.MagicLinkTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Accounts.MagicLinkToken
  alias BemedaPersonal.Repo

  describe "magic link authentication" do
    setup do
      user = user_fixture(%{magic_link_enabled: true})
      %{user: user}
    end

    test "deliver_magic_link/2 creates token and returns success", %{user: user} do
      assert {:ok, token} = Accounts.deliver_magic_link(user, &"http://example.com/#{&1}")
      assert token.user_id == user.id
      assert token.context == "magic_link"
      assert token.sent_to == user.email
      assert is_binary(token.token)
      assert byte_size(token.token) == 32
      assert is_nil(token.used_at)

      # Verify token is saved in database
      saved_token = Repo.get_by(MagicLinkToken, user_id: user.id, context: "magic_link")
      assert saved_token.token == token.token
    end

    test "deliver_magic_link/2 fails for user without magic links enabled" do
      user = user_fixture(%{magic_link_enabled: false})

      assert {:error, :magic_links_disabled} =
               Accounts.deliver_magic_link(user, &"http://example.com/#{&1}")
    end

    test "verify_magic_link/1 authenticates valid token", %{user: user} do
      {:ok, token} = Accounts.deliver_magic_link(user, & &1)
      encoded = Base.url_encode64(token.token, padding: false)

      assert {:ok, verified_user} = Accounts.verify_magic_link(encoded)
      assert verified_user.id == user.id

      # Verify token is marked as used
      saved_token = Repo.get!(MagicLinkToken, token.id)
      assert %DateTime{} = saved_token.used_at
    end

    test "verify_magic_link/1 fails for used token", %{user: user} do
      {:ok, token} = Accounts.deliver_magic_link(user, & &1)
      encoded = Base.url_encode64(token.token, padding: false)

      # Use the token
      assert {:ok, _user} = Accounts.verify_magic_link(encoded)

      # Try to use again
      assert {:error, :invalid_or_expired} = Accounts.verify_magic_link(encoded)
    end

    test "verify_magic_link/1 fails for expired token", %{user: user} do
      {:ok, token} = Accounts.deliver_magic_link(user, & &1)

      # Manually expire the token
      expired_time =
        DateTime.utc_now()
        |> DateTime.add(-3600, :second)
        |> DateTime.truncate(:second)

      token
      |> Ecto.Changeset.change(inserted_at: expired_time)
      |> Repo.update!()

      encoded = Base.url_encode64(token.token, padding: false)
      assert {:error, :invalid_or_expired} = Accounts.verify_magic_link(encoded)
    end

    test "verify_magic_link/1 fails for malformed token" do
      assert {:error, :invalid_or_expired} = Accounts.verify_magic_link("invalid-token")
      assert {:error, :invalid_or_expired} = Accounts.verify_magic_link("")
      assert {:error, :invalid_or_expired} = Accounts.verify_magic_link(nil)
    end

    test "verify_magic_link/1 fails for non-existent token" do
      random_bytes = :crypto.strong_rand_bytes(32)
      fake_token = Base.url_encode64(random_bytes, padding: false)

      assert {:error, :invalid_or_expired} = Accounts.verify_magic_link(fake_token)
    end

    test "rate limiting prevents too many requests", %{user: user} do
      # First 3 should succeed
      for i <- 1..3 do
        assert {:ok, _token} = Accounts.deliver_magic_link(user, &"http://example.com/#{&1}#{i}")
      end

      # Fourth should fail
      assert {:error, :too_many_requests} =
               Accounts.deliver_magic_link(user, &"http://example.com/#{&1}")
    end

    test "rate limiting resets after time passes", %{user: user} do
      # Exhaust rate limit
      for _index <- 1..3 do
        assert {:ok, _token} = Accounts.deliver_magic_link(user, & &1)
      end

      assert {:error, :too_many_requests} = Accounts.deliver_magic_link(user, & &1)

      # Manually reset both rate limiting mechanisms (simulating time passing)
      {:ok, _updated_user} = Accounts.reset_magic_link_send_count(user)
      :ok = Accounts.clear_recent_magic_link_tokens(user)

      # Should work again
      assert {:ok, _token} = Accounts.deliver_magic_link(user, & &1)
    end

    test "multiple users have independent rate limiting" do
      user1 = user_fixture(%{magic_link_enabled: true})
      user2 = user_fixture(%{magic_link_enabled: true})

      # Exhaust rate limit for user1
      for _i <- 1..3 do
        assert {:ok, _token} = Accounts.deliver_magic_link(user1, & &1)
      end

      assert {:error, :too_many_requests} = Accounts.deliver_magic_link(user1, & &1)

      # user2 should still work
      assert {:ok, _token} = Accounts.deliver_magic_link(user2, & &1)
    end
  end

  describe "sudo mode" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "deliver_sudo_magic_link/2 creates sudo token", %{user: user} do
      assert {:ok, token} = Accounts.deliver_sudo_magic_link(user, &"http://example.com/#{&1}")
      assert token.context == "sudo"
      assert token.user_id == user.id
      assert token.sent_to == user.email

      # Verify token is saved in database
      saved_token = Repo.get_by(MagicLinkToken, user_id: user.id, context: "sudo")
      assert saved_token.token == token.token
    end

    test "verify_sudo_token/1 verifies sudo token and updates timestamp", %{user: user} do
      {:ok, token} = Accounts.deliver_sudo_magic_link(user, & &1)
      encoded = Base.url_encode64(token.token, padding: false)

      refute Accounts.has_recent_sudo?(user)

      {:ok, updated_user} = Accounts.verify_sudo_token(encoded)

      assert Accounts.has_recent_sudo?(updated_user)
      assert %DateTime{} = updated_user.last_sudo_at

      # Verify token is marked as used
      saved_token = Repo.get!(MagicLinkToken, token.id)
      assert %DateTime{} = saved_token.used_at
    end

    test "verify_sudo_token/1 fails for invalid token", %{user: _user} do
      assert {:error, :invalid_or_expired} = Accounts.verify_sudo_token("invalid")
    end

    test "verify_sudo_token/1 fails for expired sudo token", %{user: user} do
      {:ok, token} = Accounts.deliver_sudo_magic_link(user, & &1)

      # Manually expire the token (sudo tokens expire in 5 minutes)
      expired_time =
        DateTime.utc_now()
        |> DateTime.add(-400, :second)
        |> DateTime.truncate(:second)

      token
      |> Ecto.Changeset.change(inserted_at: expired_time)
      |> Repo.update!()

      encoded = Base.url_encode64(token.token, padding: false)
      assert {:error, :invalid_or_expired} = Accounts.verify_sudo_token(encoded)
    end

    test "has_recent_sudo?/1 returns true after sudo auth", %{user: user} do
      refute Accounts.has_recent_sudo?(user)

      {:ok, token} = Accounts.deliver_sudo_magic_link(user, & &1)
      encoded = Base.url_encode64(token.token, padding: false)
      {:ok, updated_user} = Accounts.verify_sudo_token(encoded)

      assert Accounts.has_recent_sudo?(updated_user)
    end

    test "has_recent_sudo?/1 returns false for nil user" do
      refute Accounts.has_recent_sudo?(nil)
    end

    test "has_recent_sudo?/1 returns false for user without sudo timestamp", %{user: user} do
      refute Accounts.has_recent_sudo?(user)
    end

    test "sudo expires after 15 minutes", %{user: user} do
      old_sudo_time =
        DateTime.utc_now()
        |> DateTime.add(-1000, :second)
        |> DateTime.truncate(:second)

      {:ok, user} =
        user
        |> Ecto.Changeset.change(last_sudo_at: old_sudo_time)
        |> Repo.update()

      refute Accounts.has_recent_sudo?(user)
    end

    test "update_user_sudo_timestamp/1 updates sudo timestamp", %{user: user} do
      refute Accounts.has_recent_sudo?(user)

      {:ok, updated_user} = Accounts.update_user_sudo_timestamp(user)

      assert Accounts.has_recent_sudo?(updated_user)
      assert %DateTime{} = updated_user.last_sudo_at
    end
  end

  describe "magic link preferences" do
    test "update_magic_link_preferences/2 enables magic links" do
      user = user_fixture(%{magic_link_enabled: false})

      assert {:ok, updated} =
               Accounts.update_magic_link_preferences(user, %{
                 magic_link_enabled: true
               })

      assert updated.magic_link_enabled == true
      refute updated.passwordless_only
    end

    test "update_magic_link_preferences/2 enables passwordless_only with magic links" do
      user = user_fixture(%{magic_link_enabled: true})

      assert {:ok, updated} =
               Accounts.update_magic_link_preferences(user, %{
                 passwordless_only: true
               })

      assert updated.magic_link_enabled == true
      assert updated.passwordless_only == true
    end

    test "passwordless_only requires magic_link_enabled" do
      user = user_fixture(%{magic_link_enabled: false})

      assert {:error, changeset} =
               Accounts.update_magic_link_preferences(user, %{
                 passwordless_only: true
               })

      assert {"can only be enabled when magic links are enabled", _validation_info} =
               changeset.errors[:passwordless_only]
    end

    test "update_magic_link_preferences/2 disables magic links and passwordless_only" do
      user = user_fixture(%{magic_link_enabled: true, passwordless_only: true})

      assert {:ok, updated} =
               Accounts.update_magic_link_preferences(user, %{
                 magic_link_enabled: false
               })

      refute updated.magic_link_enabled
      refute updated.passwordless_only
    end

    test "update_magic_link_preferences/2 validates invalid preferences" do
      user = user_fixture()

      assert {:error, changeset} =
               Accounts.update_magic_link_preferences(user, %{
                 magic_link_enabled: "invalid"
               })

      assert changeset.errors[:magic_link_enabled]
    end

    test "update_magic_link_preferences/2 resets send count when disabling" do
      user = user_fixture(%{magic_link_enabled: true, magic_link_send_count: 2})

      assert {:ok, updated} =
               Accounts.update_magic_link_preferences(user, %{
                 magic_link_enabled: false
               })

      assert updated.magic_link_send_count == 0
    end
  end

  describe "magic link context handling" do
    test "different contexts create separate tokens" do
      user = user_fixture(%{magic_link_enabled: true})

      {:ok, magic_token} = Accounts.deliver_magic_link(user, & &1)
      {:ok, sudo_token} = Accounts.deliver_sudo_magic_link(user, & &1)

      assert magic_token.context == "magic_link"
      assert sudo_token.context == "sudo"
      assert magic_token.token != sudo_token.token

      # Both tokens exist in database
      assert Repo.get_by(MagicLinkToken, context: "magic_link", user_id: user.id)
      assert Repo.get_by(MagicLinkToken, context: "sudo", user_id: user.id)
    end

    test "context tokens don't interfere with each other" do
      user = user_fixture(%{magic_link_enabled: true})

      {:ok, magic_token} = Accounts.deliver_magic_link(user, & &1)
      {:ok, sudo_token} = Accounts.deliver_sudo_magic_link(user, & &1)

      # Use magic link token
      encoded_magic = Base.url_encode64(magic_token.token, padding: false)
      assert {:ok, _user} = Accounts.verify_magic_link(encoded_magic)

      # Sudo token should still be valid
      encoded_sudo = Base.url_encode64(sudo_token.token, padding: false)
      assert {:ok, _user} = Accounts.verify_sudo_token(encoded_sudo)
    end
  end

  describe "cleanup and maintenance" do
    test "expired tokens remain in database but are unusable" do
      user = user_fixture(%{magic_link_enabled: true})
      {:ok, token} = Accounts.deliver_magic_link(user, & &1)

      # Manually expire the token
      expired_time =
        DateTime.utc_now()
        |> DateTime.add(-3600, :second)
        |> DateTime.truncate(:second)

      token
      |> Ecto.Changeset.change(inserted_at: expired_time)
      |> Repo.update!()

      # Token still exists but is unusable
      assert Repo.get!(MagicLinkToken, token.id)

      encoded = Base.url_encode64(token.token, padding: false)
      assert {:error, :invalid_or_expired} = Accounts.verify_magic_link(encoded)
    end

    test "used tokens remain in database but are unusable" do
      user = user_fixture(%{magic_link_enabled: true})
      {:ok, token} = Accounts.deliver_magic_link(user, & &1)

      encoded = Base.url_encode64(token.token, padding: false)
      assert {:ok, _user} = Accounts.verify_magic_link(encoded)

      # Token still exists but is marked as used
      used_token = Repo.get!(MagicLinkToken, token.id)
      assert %DateTime{} = used_token.used_at

      # Cannot be used again
      assert {:error, :invalid_or_expired} = Accounts.verify_magic_link(encoded)
    end
  end
end
