defmodule BemedaPersonal.Repo.Migrations.AddTitleToInterviews do
  use Ecto.Migration

  def change do
    alter table(:interviews) do
      add :title, :string
    end
  end
end
