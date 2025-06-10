defmodule BemedaPersonal.Repo.Migrations.AddUserTypeToUsersAndSetExisting do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :user_type, :string, default: "job_seeker", null: false
    end

    execute """
    UPDATE users
    SET user_type = 'employer'
    WHERE id IN (
      SELECT DISTINCT admin_user_id
      FROM companies
      WHERE admin_user_id IS NOT NULL
    )
    """
  end

  def down do
    alter table(:users) do
      remove :user_type
    end
  end
end
