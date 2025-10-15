defmodule BemedaPersonal.Repo.Migrations.AddRegistrationSourceToUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :registration_source, :string, default: "email"
    end

    execute """
    UPDATE users
    SET registration_source = 'email'
    WHERE registration_source IS NULL
    """
  end

  def down do
    alter table(:users) do
      remove :registration_source
    end
  end
end
