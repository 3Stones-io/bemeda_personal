defmodule BemedaPersonal.Repo.Migrations.AddMagicLinkSupport do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :magic_link_enabled, :boolean, default: false, null: false
      add :last_magic_link_sent_at, :utc_datetime
      add :magic_link_send_count, :integer, default: 0
      add :passwordless_only, :boolean, default: false, null: false
      add :last_sudo_at, :utc_datetime
      add :magic_link_reset_at, :utc_datetime
    end

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

  def down do
    drop_if_exists index(:magic_link_tokens, [:inserted_at])
    drop_if_exists index(:magic_link_tokens, [:context, :token])
    drop_if_exists index(:magic_link_tokens, [:user_id])

    drop_if_exists table(:magic_link_tokens)

    alter table(:users) do
      remove :magic_link_reset_at
      remove :last_sudo_at
      remove :passwordless_only
      remove :magic_link_send_count
      remove :last_magic_link_sent_at
      remove :magic_link_enabled
    end
  end
end
