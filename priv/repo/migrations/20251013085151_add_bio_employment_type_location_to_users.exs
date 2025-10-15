defmodule BemedaPersonal.Repo.Migrations.AddBioEmploymentTypeLocationToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :bio, :text
      add :employment_type, {:array, :string}
      add :location, :string
    end
  end
end
