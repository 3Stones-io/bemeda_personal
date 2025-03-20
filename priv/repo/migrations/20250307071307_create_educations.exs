defmodule BemedaPersonal.Repo.Migrations.CreateEducations do
  use Ecto.Migration

  def change do
    create table(:educations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :institution, :string, null: false
      add :degree, :string
      add :field_of_study, :string
      add :start_date, :date, null: false
      add :end_date, :date
      add :current, :boolean, default: false, null: false
      add :description, :text
      add :resume_id, references(:resumes, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:educations, [:resume_id])
  end
end
