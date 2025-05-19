defmodule BemedaPersonal.Repo.Migrations.CreateJobApplicationStateTransitions do
  use Ecto.Migration

  def change do
    create table(:job_application_state_transitions, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :job_application_id,
          references(:job_applications, on_delete: :delete_all, type: :binary_id),
          null: false

      add :from_state, :string, null: false
      add :to_state, :string, null: false
      add :transitioned_by_id, references(:users, on_delete: :nilify_all, type: :binary_id)
      add :notes, :text

      timestamps()
    end

    create index(:job_application_state_transitions, [:job_application_id])
  end
end
