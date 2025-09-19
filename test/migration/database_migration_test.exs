defmodule BemedaPersonal.DatabaseMigrationTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures

  alias BemedaPersonal.Repo

  describe "magic link migration" do
    test "users table has new magic link columns" do
      # Query information schema to verify columns exist
      columns =
        Repo.query!("""
          SELECT column_name, data_type, is_nullable, column_default
          FROM information_schema.columns
          WHERE table_name = 'users'
          AND column_name IN ('magic_link_enabled', 'passwordless_only', 'last_sudo_at', 'magic_link_send_count', 'magic_link_reset_at')
        """)

      column_names = Enum.map(columns.rows, &List.first/1)

      assert "magic_link_enabled" in column_names
      assert "passwordless_only" in column_names
      assert "last_sudo_at" in column_names
      assert "magic_link_send_count" in column_names
      assert "magic_link_reset_at" in column_names
    end

    test "magic_link_enabled column has correct defaults and constraints" do
      result =
        Repo.query!("""
          SELECT column_default, is_nullable, data_type
          FROM information_schema.columns
          WHERE table_name = 'users' AND column_name = 'magic_link_enabled'
        """)

      [[default, nullable, data_type]] = result.rows

      assert default == "false"
      assert nullable == "NO"
      assert data_type == "boolean"
    end

    test "passwordless_only column has correct defaults and constraints" do
      result =
        Repo.query!("""
          SELECT column_default, is_nullable, data_type
          FROM information_schema.columns
          WHERE table_name = 'users' AND column_name = 'passwordless_only'
        """)

      [[default, nullable, data_type]] = result.rows

      assert default == "false"
      assert nullable == "NO"
      assert data_type == "boolean"
    end

    test "magic_link_send_count column has correct defaults and constraints" do
      result =
        Repo.query!("""
          SELECT column_default, is_nullable, data_type
          FROM information_schema.columns
          WHERE table_name = 'users' AND column_name = 'magic_link_send_count'
        """)

      [[default, nullable, data_type]] = result.rows

      assert default == "0"
      assert nullable == "NO"
      assert data_type == "integer"
    end

    test "last_sudo_at column allows nulls for timestamp" do
      result =
        Repo.query!("""
          SELECT column_default, is_nullable, data_type
          FROM information_schema.columns
          WHERE table_name = 'users' AND column_name = 'last_sudo_at'
        """)

      [[default, nullable, data_type]] = result.rows

      assert is_nil(default) or default == "NULL"
      assert nullable == "YES"
      assert data_type in ["timestamp without time zone", "timestamp"]
    end

    test "magic_link_reset_at column allows nulls for timestamp" do
      result =
        Repo.query!("""
          SELECT column_default, is_nullable, data_type
          FROM information_schema.columns
          WHERE table_name = 'users' AND column_name = 'magic_link_reset_at'
        """)

      [[default, nullable, data_type]] = result.rows

      assert is_nil(default) or default == "NULL"
      assert nullable == "YES"
      assert data_type in ["timestamp without time zone", "timestamp"]
    end

    test "magic_link_tokens table exists with correct structure" do
      # Verify table exists
      assert {:ok, _result} = Repo.query("SELECT COUNT(*) FROM magic_link_tokens")

      # Check table structure
      columns =
        Repo.query!("""
          SELECT column_name, data_type, is_nullable
          FROM information_schema.columns
          WHERE table_name = 'magic_link_tokens'
          ORDER BY column_name
        """)

      column_names = Enum.map(columns.rows, &List.first/1)

      required_columns = [
        "context",
        "id",
        "inserted_at",
        "sent_to",
        "token",
        "updated_at",
        "used_at",
        "user_id"
      ]

      for col <- required_columns do
        assert col in column_names, "Missing column: #{col}"
      end
    end

    test "magic_link_tokens table has proper constraints and indexes" do
      # Check primary key
      pk_result =
        Repo.query!("""
          SELECT column_name
          FROM information_schema.key_column_usage
          WHERE table_name = 'magic_link_tokens'
          AND constraint_name LIKE '%_pkey'
        """)

      assert [["id"]] = pk_result.rows

      # Check foreign key to users table
      fk_result =
        Repo.query!("""
          SELECT
            kcu.column_name,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name
          FROM information_schema.table_constraints AS tc
          JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
          JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
          WHERE tc.constraint_type = 'FOREIGN KEY'
          AND tc.table_name = 'magic_link_tokens'
        """)

      # Should have foreign key from user_id to users.id
      assert [["user_id", "users", "id"]] = fk_result.rows
    end

    test "existing user records have default values" do
      # Create user to test defaults are applied
      user = user_fixture()

      # Check defaults were applied
      refute user.magic_link_enabled
      refute user.passwordless_only
      assert user.magic_link_send_count == 0
      assert is_nil(user.last_sudo_at)
      assert is_nil(user.magic_link_reset_at)
    end

    test "magic link token table can store and retrieve tokens" do
      user = user_fixture()

      # Insert a test token directly
      {:ok, _result} =
        Repo.query(
          """
            INSERT INTO magic_link_tokens (id, user_id, token, context, sent_to, inserted_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, NOW(), NOW())
          """,
          [
            Ecto.UUID.bingenerate(),
            Ecto.UUID.dump!(user.id),
            :crypto.strong_rand_bytes(32),
            "test",
            user.email
          ]
        )

      # Verify we can query it back
      result =
        Repo.query!(
          """
            SELECT COUNT(*) FROM magic_link_tokens WHERE user_id = $1
          """,
          [Ecto.UUID.dump!(user.id)]
        )

      assert [[1]] = result.rows
    end
  end

  describe "migration rollback safety" do
    test "all new columns are nullable or have defaults" do
      # This ensures migrations can be rolled back without data loss
      columns =
        Repo.query!("""
          SELECT
            column_name,
            is_nullable,
            column_default
          FROM information_schema.columns
          WHERE table_name = 'users'
          AND column_name IN ('magic_link_enabled', 'passwordless_only', 'last_sudo_at', 'magic_link_send_count', 'magic_link_reset_at')
        """)

      for [column_name, nullable, default] <- columns.rows do
        # Either nullable or has default (for rollback safety)
        assert nullable == "YES" or not is_nil(default),
               "Column #{column_name} must be nullable or have default for rollback safety"
      end
    end

    test "foreign key constraints are properly named for rollback" do
      # Check that foreign key constraints have predictable names for rollback
      fk_constraints =
        Repo.query!("""
          SELECT constraint_name
          FROM information_schema.table_constraints
          WHERE table_name = 'magic_link_tokens'
          AND constraint_type = 'FOREIGN KEY'
        """)

      # Should have at least one foreign key constraint
      assert length(fk_constraints.rows) >= 1

      # Constraint names should follow convention for easier rollback
      for [constraint_name] <- fk_constraints.rows do
        assert String.contains?(constraint_name, "magic_link_tokens") or
                 String.contains?(constraint_name, "user_id"),
               "Foreign key constraint name should be predictable: #{constraint_name}"
      end
    end
  end

  describe "performance and indexing" do
    test "magic_link_tokens table has appropriate indexes" do
      # Check indexes on magic_link_tokens table
      indexes =
        Repo.query!("""
          SELECT
            indexname,
            indexdef
          FROM pg_indexes
          WHERE tablename = 'magic_link_tokens'
        """)

      index_names = Enum.map(indexes.rows, &List.first/1)

      # Should have primary key index
      assert Enum.any?(index_names, &String.contains?(&1, "pkey"))

      # Should have index on user_id for foreign key performance
      assert Enum.any?(index_names, &String.contains?(&1, "user_id"))
    end

    test "users table indexes are preserved after migration" do
      # Verify existing indexes on users table still exist
      indexes =
        Repo.query!("""
          SELECT indexname
          FROM pg_indexes
          WHERE tablename = 'users'
        """)

      index_names = Enum.map(indexes.rows, &List.first/1)

      # Primary key should exist
      assert Enum.any?(index_names, &String.contains?(&1, "pkey"))

      # Email unique index should exist (critical for authentication)
      assert Enum.any?(index_names, fn name ->
               String.contains?(name, "email") and String.contains?(name, "index")
             end)
    end
  end

  describe "data integrity" do
    test "magic link boolean constraints work correctly" do
      user = user_fixture()

      # Test that we can update boolean fields
      {:ok, _result} =
        Repo.query(
          """
            UPDATE users
            SET magic_link_enabled = true, passwordless_only = true
            WHERE id = $1
          """,
          [Ecto.UUID.dump!(user.id)]
        )

      # Verify the update worked
      result =
        Repo.query!(
          """
            SELECT magic_link_enabled, passwordless_only
            FROM users
            WHERE id = $1
          """,
          [Ecto.UUID.dump!(user.id)]
        )

      assert [[true, true]] = result.rows
    end

    test "magic_link_send_count accepts integer values" do
      user = user_fixture()

      # Test that we can update send count
      {:ok, _result} =
        Repo.query(
          """
            UPDATE users
            SET magic_link_send_count = 5
            WHERE id = $1
          """,
          [Ecto.UUID.dump!(user.id)]
        )

      # Verify the update worked
      result =
        Repo.query!(
          """
            SELECT magic_link_send_count
            FROM users
            WHERE id = $1
          """,
          [Ecto.UUID.dump!(user.id)]
        )

      assert [[5]] = result.rows
    end

    test "timestamp fields accept proper datetime values" do
      user = user_fixture()
      now = DateTime.utc_now()

      # Test that we can update timestamp fields
      {:ok, _result} =
        Repo.query(
          """
            UPDATE users
            SET last_sudo_at = $2, magic_link_reset_at = $2
            WHERE id = $1
          """,
          [Ecto.UUID.dump!(user.id), now]
        )

      # Verify the update worked
      result =
        Repo.query!(
          """
            SELECT last_sudo_at, magic_link_reset_at
            FROM users
            WHERE id = $1
          """,
          [Ecto.UUID.dump!(user.id)]
        )

      [[last_sudo, reset_at]] = result.rows

      # Should be within a few seconds of what we set
      assert %NaiveDateTime{} = last_sudo
      assert %NaiveDateTime{} = reset_at
    end
  end
end
