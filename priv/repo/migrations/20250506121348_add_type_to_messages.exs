defmodule BemedaPersonal.Repo.Migrations.AddTypeToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :type, :string, null: false, default: "user"
    end
  end
end
