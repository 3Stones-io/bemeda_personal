defmodule BemedaPersonal.Repo.Migrations.RemoveWorkloadFromJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      remove :workload, {:array, :string}
    end
  end
end
