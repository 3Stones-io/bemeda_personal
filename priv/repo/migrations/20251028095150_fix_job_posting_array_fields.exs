defmodule BemedaPersonal.Repo.Migrations.FixJobPostingArrayFields do
  use Ecto.Migration

  def up do
    execute """
    UPDATE job_postings
    SET department = 'Other'
    WHERE department IS NOT NULL
    """

    execute """
    UPDATE job_postings
    SET region = 'Zurich'
    WHERE region IS NOT NULL
    """

    execute """
    UPDATE companies
    SET location = 'Zurich'
    WHERE location IS NOT NULL
    """
  end

  def down do
  end
end
