defmodule BemedaPersonal.Repo.Migrations.AddContractTimestampsToJobOffers do
  use Ecto.Migration

  def change do
    alter table(:job_offers) do
      add :contract_generated_at, :utc_datetime
      add :contract_signed_at, :utc_datetime
    end
  end
end
