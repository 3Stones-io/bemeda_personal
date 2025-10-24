defmodule BemedaPersonal.Repo.Migrations.MigrateEmploymentTypeValues do
  use Ecto.Migration

  def up do
    execute """
    UPDATE job_postings
    SET employment_type = 'Full-time Hire'
    WHERE employment_type = 'Permanent Position'
    """

    execute """
    UPDATE job_postings
    SET employment_type = 'Contract Hire'
    WHERE employment_type IN ('Floater', 'Staff Pool', 'Temporary Assignment')
    """
  end

  def down do
    execute """
    UPDATE job_postings
    SET employment_type = 'Permanent Position'
    WHERE employment_type = 'Full-time Hire'
    """

    execute """
    UPDATE job_postings
    SET employment_type = 'Temporary Assignment'
    WHERE employment_type = 'Contract Hire'
    """
  end
end
