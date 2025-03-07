defmodule BemedaPersonal.Repo.Migrations.CreateWorkExperiences do
  use Ecto.Migration

  def change do
    create table(:work_experiences, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :company_name, :string, null: false
      add :title, :string, null: false
      add :location, :string
      add :start_date, :date, null: false
      add :end_date, :date
      add :current, :boolean, default: false, null: false
      add :description, :text
      add :resume_id, references(:resumes, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:work_experiences, [:resume_id])

    create index(:work_experiences, [:resume_id, :company_name, :start_date],
             name: :work_experiences_resume_company_start_idx
           )

    create index(:work_experiences, [:resume_id, :current],
             name: :work_experiences_resume_current_idx
           )
  end
end
