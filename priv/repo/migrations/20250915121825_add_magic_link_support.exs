defmodule BemedaPersonal.Repo.Migrations.AddMagicLinkSupport do
  use Ecto.Migration

  def change do
    # Add columns to existing users table
    alter table(:users) do
      add :magic_link_enabled, :boolean, default: false, null: false
      add :last_magic_link_sent_at, :utc_datetime
      add :magic_link_send_count, :integer, default: 0
      add :passwordless_only, :boolean, default: false, null: false
      add :last_sudo_at, :utc_datetime
      add :magic_link_reset_at, :utc_datetime
    end

    # Create new table for magic link tokens
    create table(:magic_link_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :used_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:magic_link_tokens, [:user_id])
    create unique_index(:magic_link_tokens, [:context, :token])
    create index(:magic_link_tokens, [:inserted_at])
  end
end
