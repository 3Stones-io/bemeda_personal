defmodule BemedaPersonal.Repo.Migrations.UpdateJobApplicationStateTransitionsToAllowedValues do
  use Ecto.Migration

  def up do
    execute """
    CREATE TABLE job_application_state_transitions_backup AS
    SELECT * FROM job_application_state_transitions
    WHERE from_state NOT IN ('applied', 'offer_extended', 'offer_accepted', 'withdrawn')
       OR to_state NOT IN ('applied', 'offer_extended', 'offer_accepted', 'withdrawn')
    """

    execute """
    UPDATE job_application_state_transitions
    SET from_state = 'applied',
        to_state = CASE
          WHEN to_state IN ('offer_extended', 'withdrawn') THEN to_state
          ELSE 'offer_extended'
        END
    WHERE from_state NOT IN ('applied', 'offer_extended', 'offer_accepted', 'withdrawn')
    """

    execute """
    UPDATE job_application_state_transitions
    SET to_state = CASE
      WHEN from_state = 'applied' AND to_state NOT IN ('offer_extended', 'withdrawn') THEN 'offer_extended'
      WHEN from_state = 'offer_extended' AND to_state NOT IN ('offer_accepted', 'withdrawn') THEN 'offer_accepted'
      WHEN from_state = 'withdrawn' AND to_state NOT IN ('applied', 'offer_accepted') THEN 'applied'
      WHEN from_state = 'offer_accepted' THEN to_state
      ELSE to_state
    END
    WHERE to_state NOT IN ('applied', 'offer_extended', 'offer_accepted', 'withdrawn')
      AND from_state IN ('applied', 'offer_extended', 'offer_accepted', 'withdrawn')
    """

    execute """
    DELETE FROM job_application_state_transitions
    WHERE from_state NOT IN ('applied', 'offer_extended', 'offer_accepted', 'withdrawn')
       OR to_state NOT IN ('applied', 'offer_extended', 'offer_accepted', 'withdrawn')
    """
  end

  def down do
    execute """
    INSERT INTO job_application_state_transitions
    SELECT * FROM job_application_state_transitions_backup
    """

    execute """
    DROP TABLE job_application_state_transitions_backup
    """
  end
end
