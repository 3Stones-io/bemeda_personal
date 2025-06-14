defmodule BemedaPersonal.Repo.Migrations.CreateJobOffers do
  use Ecto.Migration

  def change do
    create table(:job_offers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :variables, :map, default: %{}, null: false
      add :status, :string, null: false, default: "pending"

      add :job_application_id,
          references(:job_applications, on_delete: :restrict, type: :binary_id),
          null: false

      add :message_id, references(:messages, on_delete: :nilify_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:job_offers, [:job_application_id])
    create index(:job_offers, [:status])
    create index(:job_offers, [:message_id])
  end
end
