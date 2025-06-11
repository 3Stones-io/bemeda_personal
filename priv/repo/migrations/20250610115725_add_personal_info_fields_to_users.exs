defmodule BemedaPersonal.Repo.Migrations.AddPersonalInfoFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :city, :string
      add :country, :string
      add :gender, :string
      add :street, :string
      add :zip_code, :string
    end
  end
end
