defmodule BemedaPersonal.Repo.Migrations.RemoveMuxDataFromJobApplications do
  use Ecto.Migration

  def up do
    execute """
    INSERT INTO media_assets (
      id, file_name, type, job_application_id, status, inserted_at, updated_at
    )
    SELECT
      gen_random_uuid(),
      mux_data->>'file_name',
      mux_data->>'type',
      id,
      'uploaded',
      NOW(),
      NOW()
    FROM job_applications
    WHERE mux_data IS NOT NULL AND mux_data->>'file_name' IS NOT NULL
    """

    alter table(:job_applications) do
      remove :mux_data
    end
  end

  def down do
    alter table(:job_applications) do
      add :mux_data, :map
    end

    flush()

    execute """
    UPDATE job_applications
    SET mux_data = jsonb_build_object(
      'file_name', ma.file_name,
      'type', ma.type
    )
    FROM media_assets ma
    WHERE ma.job_application_id = job_applications.id
    AND ma.status = 'uploaded'
    """
  end
end
