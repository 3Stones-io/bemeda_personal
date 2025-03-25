defmodule BemedaPersonal.Repo.Migrations.CreateCompanies do
  use Ecto.Migration

  def change do
    create table(:companies, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :text
      add :industry, :string
      add :size, :string
      add :website_url, :text
      add :location, :string
      add :logo_url, :text
      add :admin_user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:companies, [:admin_user_id])
  end
end
