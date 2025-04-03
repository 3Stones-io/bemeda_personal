defmodule BemedaPersonal.Repo.Migrations.CreateJobPostings do
  use Ecto.Migration

  def change do
    create table(:job_postings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :description, :text, null: false
      add :location, :string
      add :employment_type, :string
      add :experience_level, :string
      add :salary_min, :integer
      add :salary_max, :integer
      add :currency, :string
      add :remote_allowed, :boolean, default: false

      add :company_id, references(:companies, on_delete: :delete_all, type: :binary_id),
        null: false

      timestamps(type: :utc_datetime)
    end

    create index(:job_postings, [:company_id])
    create index(:job_postings, [:location])
    create index(:job_postings, [:remote_allowed])
  end
end
