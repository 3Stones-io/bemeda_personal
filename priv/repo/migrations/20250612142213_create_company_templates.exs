defmodule BemedaPersonal.Repo.Migrations.CreateCompanyTemplates do
  use Ecto.Migration

  def change do
    create table(:company_templates, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :company_id, references(:companies, on_delete: :delete_all, type: :binary_id),
        null: false

      add :name, :string, null: false
      add :variables, {:array, :string}, default: []
      add :status, :string, null: false, default: "uploading"
      add :error_message, :string

      timestamps(type: :utc_datetime)
    end

    create index(:company_templates, [:company_id])
    create index(:company_templates, [:status])

    create unique_index(:company_templates, [:company_id],
             where: "status = 'active'",
             name: "company_templates_single_active_index"
           )
  end
end
