defmodule BemedaPersonal.Repo.Migrations.AddSkillsAndContractDurationToJobPostings do
  use Ecto.Migration

  def up do
    alter table(:job_postings) do
      add :skills, {:array, :string}
      add :contract_duration, :string
      add :swiss_only, :boolean
      add :net_pay, :decimal
      add :is_draft, :boolean, default: true
      modify :region, :string
      modify :department, :string
      modify :remote_allowed, :boolean, default: nil
    end

    execute "UPDATE job_postings SET is_draft = false WHERE is_draft IS NULL"

    alter table(:job_postings) do
      remove :profession
    end
  end

  def down do
    alter table(:job_postings) do
      add :profession, :string
    end

    alter table(:job_postings) do
      modify :remote_allowed, :boolean, default: false
      modify :department, :string
      modify :region, :string
      remove :is_draft
      remove :net_pay
      remove :swiss_only
      remove :contract_duration
      remove :skills
    end
  end
end
