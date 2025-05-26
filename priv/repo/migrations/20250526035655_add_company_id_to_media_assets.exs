defmodule BemedaPersonal.Repo.Migrations.AddCompanyIdToMediaAssets do
  use Ecto.Migration

  def change do
    alter table(:media_assets) do
      add :company_id, references(:companies, on_delete: :delete_all, type: :binary_id)
    end

    drop constraint(:media_assets, :exactly_one_parent)

    create(
      constraint(
        :media_assets,
        :exactly_one_parent,
        check: "num_nonnulls(job_application_id, job_posting_id, message_id, company_id) = 1"
      )
    )

    create index(:media_assets, [:company_id])
  end
end
