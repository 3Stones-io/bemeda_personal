defmodule BemedaPersonal.Repo.Migrations.AddAverageRatingToUsersAndCompanies do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :average_rating, :decimal, default: nil
    end

    alter table(:companies) do
      add :average_rating, :decimal, default: nil
    end
  end
end
