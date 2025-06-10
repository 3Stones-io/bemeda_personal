defmodule BemedaPersonal.Repo.Migrations.UpdateJobApplicationStateTransitionsToAllowedValues do
  use Ecto.Migration

  def up do
    # Update job applications with removed states to valid states
    execute """
    UPDATE job_applications
    SET state = CASE
        WHEN state IN ('under_review', 'screening', 'interview_scheduled', 'interviewed') THEN 'applied'
        WHEN state IN ('offer_declined', 'rejected') THEN 'withdrawn'
        ELSE state
    END
    WHERE state NOT IN ('applied', 'offer_extended', 'offer_accepted', 'withdrawn')
    """

    # Update transitions to map removed states to valid ones
    execute """
    UPDATE job_application_state_transitions
    SET
        from_state = CASE
            WHEN from_state IN ('under_review', 'screening', 'interview_scheduled', 'interviewed') THEN 'applied'
            WHEN from_state IN ('offer_declined', 'rejected') THEN 'withdrawn'
            ELSE from_state
        END,
        to_state = CASE
            WHEN to_state IN ('under_review', 'screening', 'interview_scheduled', 'interviewed') THEN 'applied'
            WHEN to_state IN ('offer_declined', 'rejected') THEN 'withdrawn'
            ELSE to_state
        END
    WHERE from_state NOT IN ('applied', 'offer_extended', 'offer_accepted', 'withdrawn')
       OR to_state NOT IN ('applied', 'offer_extended', 'offer_accepted', 'withdrawn')
    """

    # Delete transitions that became no-ops (same from_state and to_state after mapping)
    execute """
    DELETE FROM job_application_state_transitions
    WHERE from_state = to_state
    """
  end

  def down do
    # No rollback - this is a one-way migration
  end
end
