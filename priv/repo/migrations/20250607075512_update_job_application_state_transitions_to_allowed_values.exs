defmodule BemedaPersonal.Repo.Migrations.UpdateJobApplicationStateTransitionsToAllowedValues do
  use Ecto.Migration

  def up do
    execute """
    DELETE FROM job_application_state_transitions
    WHERE from_state NOT IN ('applied', 'offer_extended', 'offer_accepted', 'withdrawn')
       OR to_state NOT IN ('applied', 'offer_extended', 'offer_accepted', 'withdrawn')
    """
  end

  def down do
  end
end
