defmodule BemedaPersonal.Repo.Migrations.CreateInterviews do
  use Ecto.Migration

  def change do
    create table(:interviews, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :job_application_id,
          references(:job_applications, type: :binary_id, on_delete: :delete_all),
          null: false

      add :scheduled_at, :utc_datetime, null: false
      add :end_time, :utc_datetime, null: false
      add :meeting_link, :string, null: false
      add :notes, :text
      add :reminder_minutes_before, :integer, default: 30
      add :status, :string, null: false, default: "scheduled"
      add :cancelled_at, :utc_datetime
      add :cancellation_reason, :text
      add :timezone, :string, null: false
      add :created_by_id, references(:users, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:interviews, [:job_application_id])
    create index(:interviews, [:scheduled_at])
    create index(:interviews, [:status])
    create index(:interviews, [:created_by_id])

    # Ensure end_time is after scheduled_at
    create constraint(:interviews, :end_time_after_start, check: "end_time > scheduled_at")
  end
end
