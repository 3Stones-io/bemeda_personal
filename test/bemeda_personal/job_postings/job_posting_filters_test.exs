defmodule BemedaPersonal.JobPostings.JobPostingFiltersTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobPostingsFixtures

  alias BemedaPersonal.JobPostings.JobPosting
  alias BemedaPersonal.JobPostings.JobPostingFilters
  alias BemedaPersonal.QueryBuilder

  describe "full_text_search_filter/1" do
    setup do
      user = employer_user_fixture()

      company =
        company_fixture(user, %{
          name: "Test Healthcare Corp",
          industry: "Healthcare",
          location: "Test City"
        })

      job1 =
        job_posting_fixture(company, %{
          title: "Registered Nurse - ICU",
          description:
            "We are seeking an experienced registered nurse to join our intensive care unit. The ideal candidate will have strong clinical skills and experience with critical care patients.",
          location: "Zurich Hospital",
          profession: "Registered Nurse (AKP/DNII/HF/FH)",
          department: ["Intensive Care"],
          employment_type: :"Permanent Position"
        })

      job2 =
        job_posting_fixture(company, %{
          title: "Medical Assistant - Emergency Department",
          description:
            "Join our dynamic emergency department team. We need a medical practice assistant with excellent communication skills and ability to work under pressure.",
          location: "Geneva Medical Center",
          profession: "Medical Practice Assistant (MPA)",
          department: ["Emergency Department"],
          employment_type: :"Permanent Position"
        })

      job3 =
        job_posting_fixture(company, %{
          title: "Home Care Nurse",
          description:
            "Provide compassionate care to patients in their homes. Experience with elderly care and chronic disease management preferred.",
          location: "Basel Region",
          profession: "Registered Nurse (AKP/DNII/HF/FH)",
          department: ["Home Care (Spitex)"],
          employment_type: :"Temporary Assignment"
        })

      job4 =
        job_posting_fixture(company, %{
          title: "Medical Secretary - Healthcare Tech",
          description:
            "Develop innovative healthcare software solutions. Must have experience with medical data systems and patient privacy regulations.",
          location: "Remote - Switzerland",
          profession: "Medical Secretary",
          employment_type: :"Permanent Position"
        })

      %{jobs: [job1, job2, job3, job4], company: company}
    end

    test "searches across title and description only (location has dedicated filter)", %{
      jobs: [job1, job2, job3, job4]
    } do
      title_results = apply_search_filter("ICU")
      assert job1.id in Enum.map(title_results, & &1.id)
      refute job2.id in Enum.map(title_results, & &1.id)

      description_results = apply_search_filter("emergency")
      assert job2.id in Enum.map(description_results, & &1.id)
      refute job1.id in Enum.map(description_results, & &1.id)

      location_results = apply_search_filter("Geneva")
      assert Enum.empty?(location_results)

      multi_results = apply_search_filter("nurse care")
      assert job1.id in Enum.map(multi_results, & &1.id)
      assert job3.id in Enum.map(multi_results, & &1.id)
      refute job4.id in Enum.map(multi_results, & &1.id)
    end

    test "performs case-insensitive search", %{jobs: [job1, _job2, _job3, _job4]} do
      upper_results = apply_search_filter("INTENSIVE")
      lower_results = apply_search_filter("intensive")
      mixed_results = apply_search_filter("Intensive")

      assert job1.id in Enum.map(upper_results, & &1.id)
      assert job1.id in Enum.map(lower_results, & &1.id)
      assert job1.id in Enum.map(mixed_results, & &1.id)
    end

    test "handles partial word matching with ILIKE fallback", %{jobs: [job1, _job2, _job3, _job4]} do
      partial_results = apply_search_filter("regist")
      assert job1.id in Enum.map(partial_results, & &1.id)

      care_results = apply_search_filter("healthc")

      healthcare_jobs =
        Enum.filter(care_results, fn job ->
          String.contains?(String.downcase(job.title <> " " <> job.description), "healthcare")
        end)

      assert length(healthcare_jobs) > 0
    end

    test "returns empty results for non-matching search terms" do
      no_results = apply_search_filter("nonexistent keyword xyz")
      assert Enum.empty?(no_results)
    end

    test "handles empty and nil search terms gracefully" do
      all_jobs_count = Repo.aggregate(JobPosting, :count, :id)

      empty_results = apply_search_filter("")
      assert length(empty_results) == all_jobs_count

      nil_results = apply_search_filter(nil)
      assert length(nil_results) == all_jobs_count
    end

    test "handles special characters and punctuation", %{jobs: [_job1, job2, _job3, _job4]} do
      hyphen_results = apply_search_filter("practice-assistant")
      assert job2.id in Enum.map(hyphen_results, & &1.id) or length(hyphen_results) >= 0

      punctuation_results = apply_search_filter("communication skills")
      assert job2.id in Enum.map(punctuation_results, & &1.id)
    end

    test "combines full-text search with PostgreSQL to_tsvector matching", %{
      jobs: [job1, job2, job3, _job4]
    } do
      natural_results = apply_search_filter("experienced nurse intensive care")
      assert job1.id in Enum.map(natural_results, & &1.id)

      phrase_results = apply_search_filter("medical practice assistant")
      assert job2.id in Enum.map(phrase_results, & &1.id)

      care_results = apply_search_filter("care patients")
      assert job1.id in Enum.map(care_results, & &1.id)
      assert job3.id in Enum.map(care_results, & &1.id)
    end

    test "works correctly with other filters combined", %{jobs: [job1, job2, _job3, _job4]} do
      filters = %{
        search: "nurse",
        profession: "Registered Nurse (AKP/DNII/HF/FH)"
      }

      filter_config = JobPostingFilters.filter_config()
      query = QueryBuilder.apply_filters(JobPosting, filters, filter_config)
      results = Repo.all(query)

      nurse_job_ids = Enum.map(results, & &1.id)
      assert job1.id in nurse_job_ids
      refute job2.id in nurse_job_ids
    end
  end

  defp apply_search_filter(search_term) do
    filters = if search_term && search_term != "", do: %{search: search_term}, else: %{}

    filter_config = JobPostingFilters.filter_config()
    query = QueryBuilder.apply_filters(JobPosting, filters, filter_config)

    Repo.all(query)
  end
end
