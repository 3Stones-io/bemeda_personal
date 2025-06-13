defmodule BemedaPersonal.Repo.Migrations.AddCompanyTemplateIdToMediaAssets do
  use Ecto.Migration

  def up do
    alter table(:media_assets) do
      add :company_template_id,
          references(:company_templates, on_delete: :delete_all, type: :binary_id)
    end

    drop constraint(:media_assets, :exactly_one_parent)

    create(
      constraint(
        :media_assets,
        :exactly_one_parent,
        check:
          "num_nonnulls(job_application_id, job_posting_id, message_id, company_id, company_template_id) = 1"
      )
    )

    create index(:media_assets, [:company_template_id])
  end

  def down do
    drop index(:media_assets, [:company_template_id])

    drop constraint(:media_assets, :exactly_one_parent)

    execute(
      "DELETE FROM media_assets WHERE company_template_id IS NOT NULL AND job_application_id IS NULL AND job_posting_id IS NULL AND message_id IS NULL AND company_id IS NULL"
    )

    create(
      constraint(
        :media_assets,
        :exactly_one_parent,
        check: "num_nonnulls(job_application_id, job_posting_id, message_id, company_id) = 1"
      )
    )

    alter table(:media_assets) do
      remove :company_template_id
    end
  end
end
