defmodule BemedaPersonal.Repo.Migrations.AddStateToJobApplications do
  use Ecto.Migration

  def change do
    alter table(:job_applications) do
      add :state, :string, null: true
    end
  end
end
