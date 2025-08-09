defmodule BemedaPersonal.Repo.Migrations.AddAddressFieldsToCompanies do
  use Ecto.Migration

  def change do
    alter table(:companies) do
      add :address, :string
      add :city, :string
      add :postal_code, :string
    end
  end
end
