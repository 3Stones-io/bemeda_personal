defmodule BemedaPersonal.Repo.Migrations.RemoveMuxDataFromMessages do
  use Ecto.Migration

  def up do
    execute """
    INSERT INTO media_assets (
      id, file_name, type, upload_id, message_id, status, inserted_at, updated_at
    )
    SELECT
      gen_random_uuid(),
      mux_data->>'file_name',
      mux_data->>'type',
      (mux_data->>'upload_id')::uuid,
      id,
      'uploaded',
      NOW(),
      NOW()
    FROM messages
    WHERE mux_data IS NOT NULL AND mux_data->>'file_name' IS NOT NULL
    """

    alter table(:messages) do
      remove :mux_data
    end
  end

  def down do
    alter table(:messages) do
      add :mux_data, :map
    end

    execute """
    UPDATE messages
    SET mux_data = jsonb_build_object(
      'file_name', ma.file_name,
      'type', ma.type,
      'upload_id', ma.upload_id
    )
    FROM media_assets ma
    WHERE ma.message_id = messages.id
    AND ma.status = 'uploaded'
    """
  end
end
