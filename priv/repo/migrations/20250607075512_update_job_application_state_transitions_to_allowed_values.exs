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

    execute """
    UPDATE job_application_state_transitions
    SET to_state = CASE
      WHEN to_state = 'rejected' THEN 'withdrawn'
      WHEN to_state = 'offer_declined' THEN 'withdrawn'
      ELSE 'applied'
    END
    WHERE to_state NOT IN ('applied', 'offer_extended', 'offer_accepted', 'withdrawn')
    """
  end

  def down do
    execute """
    UPDATE job_application_state_transitions
    SET from_state = CASE
      WHEN from_state = 'withdrawn' THEN 'rejected'
      ELSE from_state
    END
    """

    execute """
    UPDATE job_application_state_transitions
    SET to_state = CASE
      WHEN to_state = 'withdrawn' THEN 'rejected'
      ELSE to_state
    END
    """
  end
end
