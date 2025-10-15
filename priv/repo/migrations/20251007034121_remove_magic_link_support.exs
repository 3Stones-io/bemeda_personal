defmodule BemedaPersonal.Repo.Migrations.RemoveMagicLinkSupport do
  use Ecto.Migration

  def up do
    alter table(:users) do
      remove :magic_link_enabled, :boolean, default: false
      remove :last_magic_link_sent_at, :utc_datetime
      remove :magic_link_send_count, :integer, default: 0
      remove :passwordless_only, :boolean, default: false
      remove :last_sudo_at, :utc_datetime
      remove :magic_link_reset_at, :utc_datetime
    end

    execute "DELETE FROM users_tokens WHERE context = 'magic-link'"

    drop_if_exists table(:magic_link_tokens)
  end

  def down do
    create_if_not_exists table(:magic_link_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(updated_at: false, type: :utc_datetime)
    end

    create_if_not_exists index(:magic_link_tokens, [:user_id])
    create_if_not_exists unique_index(:magic_link_tokens, [:context, :token])
    create_if_not_exists index(:magic_link_tokens, [:inserted_at])

    alter table(:users) do
      add_if_not_exists :magic_link_enabled, :boolean, default: false
      add_if_not_exists :last_magic_link_sent_at, :utc_datetime
      add_if_not_exists :magic_link_send_count, :integer, default: 0
      add_if_not_exists :passwordless_only, :boolean, default: false
      add_if_not_exists :last_sudo_at, :utc_datetime
      add_if_not_exists :magic_link_reset_at, :utc_datetime
    end
  end
end
