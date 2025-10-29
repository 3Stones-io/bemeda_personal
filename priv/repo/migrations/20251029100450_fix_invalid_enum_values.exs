defmodule BemedaPersonal.Repo.Migrations.FixInvalidEnumValues do
  use Ecto.Migration

  def up do
    execute """
    UPDATE companies
    SET location = NULL
    WHERE location NOT IN (
      'Aargau', 'Appenzell Ausserrhoden', 'Appenzell Innerrhoden',
      'Basel-Landschaft', 'Basel-Stadt', 'Bern', 'Fribourg', 'Geneva',
      'Glarus', 'Grisons', 'Jura', 'Lucerne', 'Neuchâtel', 'Nidwalden',
      'Obwalden', 'Schaffhausen', 'Schwyz', 'Solothurn', 'St. Gallen',
      'Thurgau', 'Ticino', 'Uri', 'Valais', 'Vaud', 'Zug', 'Zurich'
    )
    """

    execute """
    UPDATE companies
    SET organization_type = NULL
    WHERE organization_type NOT IN (
      'Care Home', 'Clinic', 'Home Care Service', 'Hospital',
      'Medical Center', 'Private Practice', 'Other'
    )
    """

    execute """
    UPDATE job_postings
    SET region = NULL
    WHERE region NOT IN (
      'Aargau', 'Appenzell Ausserrhoden', 'Appenzell Innerrhoden',
      'Basel-Landschaft', 'Basel-Stadt', 'Bern', 'Fribourg', 'Geneva',
      'Glarus', 'Grisons', 'Jura', 'Lucerne', 'Neuchâtel', 'Nidwalden',
      'Obwalden', 'Schaffhausen', 'Schwyz', 'Solothurn', 'St. Gallen',
      'Thurgau', 'Ticino', 'Uri', 'Valais', 'Vaud', 'Zug', 'Zurich'
    )
    """

    execute """
    UPDATE job_postings
    SET department = NULL
    WHERE department NOT IN (
      'Acute Care', 'Administration', 'Anesthesia', 'Day Clinic',
      'Emergency Department', 'Home Care (Spitex)', 'Hospital / Clinic',
      'Intensive Care', 'Intermediate Care (IMC)', 'Long-Term Care',
      'Medical Practices', 'Operating Room', 'Other', 'Psychiatry',
      'Recovery Room (PACU)', 'Rehabilitation', 'Therapies'
    )
    """
  end

  def down do
  end
end
