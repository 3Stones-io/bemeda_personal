defmodule BemedaPersonal.Repo.Migrations.AddVideoUploadsToJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      add :mux_data, :map
    end
  end
end
