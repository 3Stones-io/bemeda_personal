defmodule BemedaPersonal.Repo.Migrations.AddAuthenticatedAtToUserTokens do
  use Ecto.Migration

  def up do
    alter table(:users_tokens) do
      add :authenticated_at, :utc_datetime
    end
  end

  def down do
    alter table(:users_tokens) do
      remove :authenticated_at, :utc_datetime
    end
  end
end
