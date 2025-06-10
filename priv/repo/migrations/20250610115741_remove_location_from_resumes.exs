defmodule BemedaPersonal.Repo.Migrations.RemoveLocationFromResumes do
  use Ecto.Migration

  def change do
    alter table(:resumes) do
      remove :location, :string
    end
  end
end
