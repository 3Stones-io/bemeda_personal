defmodule BemedaPersonal.Repo.Migrations.RemoveMuxDataFromJobApplications do
  use Ecto.Migration

  def up do
    alter table(:job_applications) do
      remove :mux_data
    end
  end

  def down do
    alter table(:job_applications) do
      add :mux_data, :map
    end
  end
end
