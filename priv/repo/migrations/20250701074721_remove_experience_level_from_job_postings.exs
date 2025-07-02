defmodule BemedaPersonal.Repo.Migrations.RemoveExperienceLevelFromJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      remove :experience_level, :string
    end
  end
end
