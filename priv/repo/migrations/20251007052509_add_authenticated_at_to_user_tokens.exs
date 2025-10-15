defmodule BemedaPersonal.Repo.Migrations.AddAuthenticatedAtToUserTokens do
  use Ecto.Migration

  def up do
    alter table(:users_tokens) do
      add :authenticated_at, :utc_datetime
    end

    execute """
    UPDATE users_tokens
    SET authenticated_at = inserted_at
    WHERE context = 'session'
    """
  end

  def down do
    alter table(:users_tokens) do
      remove :authenticated_at, :utc_datetime
    end
  end
end
