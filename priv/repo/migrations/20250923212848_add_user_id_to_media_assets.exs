defmodule BemedaPersonal.Repo.Migrations.AddUserIdToMediaAssets do
  use Ecto.Migration

  def change do
    alter table(:media_assets) do
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)
    end

    create index(:media_assets, [:user_id])
  end
end
