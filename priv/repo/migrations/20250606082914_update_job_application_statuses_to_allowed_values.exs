defmodule BemedaPersonal.Repo.Migrations.UpdateJobApplicationStatusesToAllowedValues do
  use Ecto.Migration

  def up do
    execute """
    UPDATE job_applications
    SET state = CASE
      WHEN state = 'rejected' THEN 'withdrawn'
      WHEN state = 'offer_declined' THEN 'withdrawn'
      ELSE 'applied'
    END
    WHERE state NOT IN ('applied', 'offer_extended', 'offer_accepted', 'withdrawn')
    """
  end

  def down do
    execute """
    UPDATE job_applications
    SET state = CASE
      WHEN state = 'withdrawn' THEN 'rejected'
      ELSE state
    END
    """
  end
end
