defmodule BemedaPersonal.Repo.Migrations.CreateMediaAssets do
  use Ecto.Migration

  def change do
    create table(:media_assets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :asset_id, :string
      add :file_name, :string
      add :playback_id, :string
      add :status, :string
      add :type, :string
      add :upload_id, :uuid

      add :job_application_id,
          references(:job_applications, on_delete: :delete_all, type: :binary_id)

      add :job_posting_id, references(:job_postings, on_delete: :delete_all, type: :binary_id)
      add :message_id, references(:messages, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:media_assets, [:asset_id])
    create index(:media_assets, [:job_application_id])
    create index(:media_assets, [:job_posting_id])
    create index(:media_assets, [:message_id])
  end
end
