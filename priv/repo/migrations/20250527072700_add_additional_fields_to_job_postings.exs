defmodule BemedaPersonal.Repo.Migrations.AddAdditionalFieldsToJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      add :department, {:array, :string}
      add :gender, {:array, :string}
      add :language, {:array, :string}
      add :part_time_details, {:array, :string}
      add :position, :string
      add :region, {:array, :string}
      add :shift_type, {:array, :string}
      add :workload, {:array, :string}
      add :years_of_experience, :string
    end
  end
end
