defmodule BemedaPersonal.Repo.Migrations.CreateResumes do
  use Ecto.Migration

  def change do
    create table(:resumes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :headline, :string
      add :summary, :text
      add :location, :string
      add :is_public, :boolean, default: false, null: false
      add :contact_email, :string
      add :phone_number, :string
      add :website_url, :string
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:resumes, [:user_id])
  end
end
