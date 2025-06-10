defmodule BemedaPersonal.Repo.Migrations.AddAddressFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :city, :string
      add :country, :string
      add :gender, :string
      add :line1, :string
      add :line2, :string
      add :title, :string
      add :zip_code, :string
    end
  end
end
