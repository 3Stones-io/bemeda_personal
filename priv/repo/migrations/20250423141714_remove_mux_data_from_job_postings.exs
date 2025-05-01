defmodule BemedaPersonal.Repo.Migrations.RemoveMuxDataFromJobPostings do
  use Ecto.Migration

  def up do
    execute """
    INSERT INTO media_assets (
      id, file_name, type, job_posting_id, status, inserted_at, updated_at
    )
    SELECT
      gen_random_uuid(),
      mux_data->>'file_name',
      mux_data->>'type',
      id,
      'uploaded',
      NOW(),
      NOW()
    FROM job_postings
    WHERE mux_data IS NOT NULL AND mux_data->>'file_name' IS NOT NULL
    """

    alter table(:job_postings) do
      remove :mux_data
    end
  end

  def down do
    alter table(:job_postings) do
      add :mux_data, :map
    end

    flush()

    execute """
    UPDATE job_postings
    SET mux_data = jsonb_build_object(
      'file_name', ma.file_name,
      'type', ma.type
    )
    FROM media_assets ma
    WHERE ma.job_posting_id = job_postings.id
    AND ma.status = 'uploaded'
    """
  end
end
