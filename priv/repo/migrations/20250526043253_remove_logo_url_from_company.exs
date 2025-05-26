defmodule BemedaPersonal.Repo.Migrations.RemoveLogoUrlFromCompany do
  use Ecto.Migration

  def change do
    alter table(:companies) do
      remove :logo_url
    end
  end
end
