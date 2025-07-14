defmodule BemedaPersonal.Repo.Migrations.AddMoreFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :date_of_birth, :date
      add :department, :string
      add :medical_role, :string
      add :phone, :string
    end
  end
end
