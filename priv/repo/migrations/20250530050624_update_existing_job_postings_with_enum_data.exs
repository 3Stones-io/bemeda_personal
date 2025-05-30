defmodule BemedaPersonal.Repo.Migrations.UpdateExistingJobPostingsWithEnumData do
  use Ecto.Migration

  import Ecto.Query

  def up do
    job_postings_query = from(jp in "job_postings", select: [:id])
    job_posting_ids = BemedaPersonal.Repo.all(job_postings_query)

    Enum.each(job_posting_ids, fn %{id: id} ->
      update_query = from(jp in "job_postings", where: jp.id == ^id)

      BemedaPersonal.Repo.update_all(update_query,
        set: [
          employment_type: set_default_employment_type(),
          experience_level: set_default_experience_level()
        ]
      )
    end)
  end

  def down do
    update_query = from(jp in "job_postings")

    BemedaPersonal.Repo.update_all(update_query,
      set: [
        employment_type: nil,
        experience_level: nil
      ]
    )
  end

  defp set_default_employment_type do
    employment_types = ["Permanent Position", "Floater", "Staff Pool", "Temporary Assignment"]
    Enum.random(employment_types)
  end

  defp set_default_experience_level do
    experience_levels = ["Junior", "Mid-level", "Senior", "Lead", "Executive"]
    Enum.random(experience_levels)
  end
end
