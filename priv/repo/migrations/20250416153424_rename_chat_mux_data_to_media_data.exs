defmodule BemedaPersonal.Repo.Migrations.RenameChatMuxDataToMediaData do
  use Ecto.Migration

  def change do
    rename table(:messages), :mux_data, to: :media_data
  end
end
