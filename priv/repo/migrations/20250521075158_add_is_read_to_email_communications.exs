defmodule BemedaPersonal.Repo.Migrations.AddIsReadToEmailCommunications do
  use Ecto.Migration

  def change do
    alter table(:email_communications) do
      add :is_read, :boolean, default: false, null: false
    end

    create index(:email_communications, [:recipient_id, :is_read])
  end
end
