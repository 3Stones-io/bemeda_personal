defmodule BemedaPersonal.Repo.Migrations.AddAdditionalFieldsToJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      add :department, :string
      add :shift_type, :string
      add :region, :string
      add :years_of_experience, :string
      add :position, :string
      add :gender, :string
      add :language, :string
      add :workload, :string
      add :part_time_details, :string
    end
  end
end
