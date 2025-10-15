defmodule BemedaPersonal.Repo.Migrations.UpdateMediaAssetsExactlyOneParentConstraint do
  use Ecto.Migration

  def up do
    drop constraint(:media_assets, :exactly_one_parent)

    create(
      constraint(
        :media_assets,
        :exactly_one_parent,
        check:
          "num_nonnulls(job_application_id, job_posting_id, message_id, company_id, company_template_id, user_id) = 1"
      )
    )
  end

  def down do
    drop constraint(:media_assets, :exactly_one_parent)

    create(
      constraint(
        :media_assets,
        :exactly_one_parent,
        check:
          "num_nonnulls(job_application_id, job_posting_id, message_id, company_id, company_template_id) = 1"
      )
    )
  end
end
