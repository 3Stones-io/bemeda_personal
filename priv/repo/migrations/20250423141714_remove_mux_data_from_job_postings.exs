defmodule BemedaPersonal.Repo.Migrations.RemoveMuxDataFromJobPostings do
  use Ecto.Migration

  def up do
    alter table(:job_postings) do
      remove :mux_data
    end
  end

  def down do
    alter table(:job_postings) do
      add :mux_data, :map
    end
  end
end
