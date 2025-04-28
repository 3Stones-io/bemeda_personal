defmodule BemedaPersonal.Repo.Migrations.CreateJobApplicationTags do
  use Ecto.Migration

  def change do
    create table(:job_application_tags, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :job_application_id,
          references(:job_applications, on_delete: :delete_all, type: :binary_id),
          null: false

      add :tag_id, references(:tags, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:job_application_tags, [:job_application_id])
    create index(:job_application_tags, [:tag_id])
    create unique_index(:job_application_tags, [:job_application_id, :tag_id])
  end
end
