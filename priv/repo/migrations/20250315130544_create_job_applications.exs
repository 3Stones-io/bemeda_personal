defmodule BemedaPersonal.Repo.Migrations.CreateJobApplications do
  use Ecto.Migration

  def change do
    create table(:job_applications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :cover_letter, :text

      add :job_posting_id, references(:job_postings, on_delete: :delete_all, type: :binary_id),
        null: false

      add :mux_data, :map

      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:job_applications, [:job_posting_id])
    create index(:job_applications, [:user_id])
  end
end
