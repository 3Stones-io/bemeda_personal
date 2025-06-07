defmodule BemedaPersonal.Repo.Migrations.UpdateJobApplicationStateTransitionsToAllowedValues do
  use Ecto.Migration

  def up do
    execute """
    UPDATE job_application_state_transitions
    SET from_state = CASE
      WHEN from_state = 'rejected' THEN 'withdrawn'
      WHEN from_state = 'offer_declined' THEN 'withdrawn'
      ELSE 'applied'
    END
    WHERE from_state NOT IN ('applied', 'offer_extended', 'offer_accepted', 'withdrawn')
    """
  end

  def down do
    execute """
    UPDATE job_application_state_transitions
    SET state = CASE
      WHEN state = 'withdrawn' THEN 'rejected'
      ELSE state
    END
    """
  end
end
