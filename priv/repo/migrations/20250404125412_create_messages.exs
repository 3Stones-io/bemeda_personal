defmodule BemedaPersonal.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content, :text
      add :sender_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      add :job_application_id,
          references(:job_applications, on_delete: :delete_all, type: :binary_id),
          null: false

      add :mux_data, :map

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:sender_id])
    create index(:messages, [:job_application_id])
  end
end
