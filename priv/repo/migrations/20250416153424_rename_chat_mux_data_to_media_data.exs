defmodule BemedaPersonal.Repo.Migrations.RenameChatMuxDataToMediaData do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      remove :mux_data
      add :media_data, :map
    end
  end
end
