defmodule BemedaPersonal.Repo.Migrations.AddStateToJobApplications do
  use Ecto.Migration

  def up do
    # First add the column as nullable
    alter table(:job_applications) do
      add :state, :string, null: true
    end

    # Update existing records
    execute "UPDATE job_applications SET state = 'applied' WHERE state IS NULL"

    # Then make it not nullable with a default value
    alter table(:job_applications) do
      modify :state, :string, null: false, default: "applied"
    end

    create index(:job_applications, [:state])
  end

  def down do
    # Drop the index first
    drop index(:job_applications, [:state])

    # Then remove the column
    alter table(:job_applications) do
      remove :state
    end
  end
end
