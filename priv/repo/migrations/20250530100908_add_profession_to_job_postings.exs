defmodule BemedaPersonal.Repo.Migrations.AddProfessionToJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      add :profession, :string
    end
  end
end
