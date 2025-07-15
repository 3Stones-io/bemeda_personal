defmodule BemedaPersonal.Repo.Migrations.AddCompanyProfileFields do
  use Ecto.Migration

  def up do
    alter table(:companies) do
      add :phone_number, :string
      add :organization_type, :string
      add :hospital_affiliation, :string
    end

    create index(:companies, [:organization_type])
  end

  def down do
    drop index(:companies, [:organization_type])

    alter table(:companies) do
      remove :phone_number, :string
      remove :organization_type, :string
      remove :hospital_affiliation, :string
    end
  end
end
