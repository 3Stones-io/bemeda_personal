defmodule BemedaPersonal.Repo.Migrations.RemoveLogoUrlFromCompany do
  use Ecto.Migration

  def up do
    alter table(:companies) do
      remove :logo_url
    end
  end

  def down do
    alter table(:companies) do
      add :logo_url, :text
    end
  end
end
