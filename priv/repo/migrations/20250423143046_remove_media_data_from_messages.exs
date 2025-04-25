defmodule BemedaPersonal.Repo.Migrations.RemoveMediaDataFromMessages do
  use Ecto.Migration

  def up do
    alter table(:messages) do
      remove :media_data
    end
  end

  def down do
    alter table(:messages) do
      add :media_data, :map
    end
  end
end
