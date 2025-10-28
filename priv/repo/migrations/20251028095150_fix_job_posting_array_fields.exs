defmodule BemedaPersonal.Repo.Migrations.FixJobPostingArrayFields do
  use Ecto.Migration

  import Ecto.Query

  alias BemedaPersonal.Repo

  def up do
    migrate_field(:department, departments())
    migrate_field(:region, regions())
  end

  def down do
  end

  defp migrate_field(field, values) do
    job_postings = Repo.all(from(jp in "job_postings", select: [:id]))

    Enum.each(job_postings, fn %{id: id} ->
      Repo.update_all(
        from(jp in "job_postings", where: jp.id == ^id),
        set: [{field, Enum.random(values)}]
      )
    end)
  end

  defp departments do
    [
      "Acute Care",
      "Administration",
      "Anesthesia",
      "Day Clinic",
      "Emergency Department",
      "Home Care (Spitex)",
      "Hospital / Clinic",
      "Intensive Care",
      "Intermediate Care (IMC)",
      "Long-Term Care",
      "Medical Practices",
      "Operating Room",
      "Other",
      "Psychiatry",
      "Recovery Room (PACU)",
      "Rehabilitation",
      "Therapies"
    ]
  end

  defp regions do
    [
      "Aargau",
      "Appenzell Ausserrhoden",
      "Appenzell Innerrhoden",
      "Basel-Landschaft",
      "Basel-Stadt",
      "Bern",
      "Fribourg",
      "Geneva",
      "Glarus",
      "Grisons",
      "Jura",
      "Lucerne",
      "Neuchâtel",
      "Nidwalden",
      "Obwalden",
      "Schaffhausen",
      "Schwyz",
      "Solothurn",
      "St. Gallen",
      "Thurgau",
      "Ticino",
      "Uri",
      "Valais",
      "Vaud",
      "Zug",
      "Zurich"
    ]
  end
end
