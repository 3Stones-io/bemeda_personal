defmodule BemedaPersonal.Repo.Migrations.UpgradeUserAuthTables do
  use Ecto.Migration

  def up do
    alter table(:users_tokens) do
      add :authenticated_at, :utc_datetime
    end

    alter table(:users) do
      modify :hashed_password, :string, null: true
    end
  end

  def down do
    alter table(:users_tokens) do
      remove :authenticated_at
    end

    alter table(:users) do
      modify :hashed_password, :string, null: false
    end
  end
end
