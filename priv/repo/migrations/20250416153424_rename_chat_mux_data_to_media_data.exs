defmodule BemedaPersonal.Repo.Migrations.RenameChatMuxDataToMediaData do
  use Ecto.Migration

  def up do
    alter table(:messages) do
      remove :mux_data
      add :media_data, :map
    end
  end

  def down do
    alter table(:messages) do
      remove :media_data
      add :mux_data, :map
    end
  end
end
