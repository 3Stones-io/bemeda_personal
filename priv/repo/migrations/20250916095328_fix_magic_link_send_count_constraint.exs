defmodule BemedaPersonal.Repo.Migrations.FixMagicLinkSendCountConstraint do
  use Ecto.Migration

  def up do
    # Fix magic_link_send_count column to be NOT NULL with proper default
    alter table(:users) do
      modify :magic_link_send_count, :integer, default: 0, null: false
    end
  end

  def down do
    # Reverse the change: remove default and allow NULL
    alter table(:users) do
      modify :magic_link_send_count, :integer, null: true
    end
  end
end
