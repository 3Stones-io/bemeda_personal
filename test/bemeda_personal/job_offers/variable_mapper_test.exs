defmodule BemedaPersonal.JobOffers.VariableMapperTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures

  alias BemedaPersonal.JobOffers.VariableMapper

  describe "auto_populate_variables/1" do
    test "populates all expected variables from job application" do
      user =
        user_fixture(%{
          city: "Zurich",
          first_name: "Alice",
          gender: :female,
          last_name: "Smith",
          locale: :en,
          street: "Main St",
          zip_code: "8000"
        })

      company =
        company_fixture(employer_user_fixture(%{locale: :en}), %{
          location: "Geneva",
          name: "Acme Corp"
        })

      job_posting =
        job_posting_fixture(company, %{
          employment_type: :"Full-time Hire",
          location: "Remote",
          title: "Engineer"
        })

      job_application = job_application_fixture(user, job_posting)

      variables = VariableMapper.auto_populate_variables(job_application)

      # Job seeker variables
      assert variables["Candidate_Full_Name"] == "Alice Smith"
      assert variables["City"] == "Zurich"
      assert variables["First_Name"] == "Alice"
      assert variables["Last_Name"] == "Smith"
      assert variables["Salutation"] == "Ms."
      assert variables["Street"] == "Main St"
      assert variables["Title"] == "Ms."
      assert variables["ZipCode"] == "8000"

      # Company variables
      assert variables["Client_Company"] == "Acme Corp"
      assert variables["Employer_Country"] == "Geneva"
      assert variables["Recruiter_Email"] == company.admin_user.email

      assert variables["Recruiter_Name"] ==
               "#{company.admin_user.first_name} #{company.admin_user.last_name}"

      # Job posting variables
      assert variables["Contract_Type"] == "Full-time Hire"
      assert variables["Job_Title"] == "Engineer"
      assert variables["Work_Location"] == "Remote"

      # System variables
      assert variables["Contract_Type"] == "Full-time Hire"
      assert variables["Date"] == Date.to_string(Date.utc_today())
      assert String.starts_with?(variables["Serial_Number"], "JO-#{Date.utc_today().year}-")

      # Manual fields should be empty strings
      assert variables["Gross_Salary"] == ""
      assert variables["Offer_Deadline"] == ""
      assert variables["Recruiter_Phone"] == ""
      assert variables["Recruiter_Position"] == ""
      assert variables["Start_Date"] == ""
      assert variables["Working_Hours"] == ""
    end

    test "handles missing optional fields gracefully" do
      user = user_fixture(%{first_name: "Bob", gender: nil, last_name: "Jones"})
      company = company_fixture(employer_user_fixture(), %{location: nil, name: "Beta LLC"})

      job_posting =
        job_posting_fixture(company, %{
          employment_type: nil,
          location: nil,
          title: "Designer"
        })

      job_application = job_application_fixture(user, job_posting)

      variables = VariableMapper.auto_populate_variables(job_application)

      assert variables["Contract_Type"] == ""
      assert variables["Employer_Country"] == ""
      assert variables["Job_Title"] == "Designer"
      assert variables["Salutation"] == ""
      assert variables["Title"] == ""
      assert variables["Work_Location"] == ""
    end

    test "generates consistent date for all applications" do
      user1 = user_fixture()
      user2 = user_fixture()
      company = company_fixture(employer_user_fixture())
      job_posting = job_posting_fixture(company)
      job_application1 = job_application_fixture(user1, job_posting)
      job_application2 = job_application_fixture(user2, job_posting)

      variables1 = VariableMapper.auto_populate_variables(job_application1)
      variables2 = VariableMapper.auto_populate_variables(job_application2)

      assert variables1["Date"] == variables2["Date"]
      assert variables1["Date"] == Date.to_string(Date.utc_today())
    end

    test "formats Place_Date with city" do
      user = user_fixture(%{city: "Geneva"})
      company = company_fixture(employer_user_fixture())
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      variables = VariableMapper.auto_populate_variables(job_application)

      assert variables["Place_Date"] =~ "Geneva, "
      assert variables["Place_Date"] =~ "#{Date.utc_today().day}"
    end
  end

  describe "contract language priority" do
    test "priority 1: job seeker locale matches job posting languages" do
      # Job seeker prefers French, job posting supports French
      job_seeker = user_fixture(%{gender: :female, locale: :fr})
      company_admin = employer_user_fixture(%{locale: :de})
      company = company_fixture(company_admin)
      job_posting = job_posting_fixture(company, %{language: [:German, :French, :English]})
      job_application = job_application_fixture(job_seeker, job_posting)

      variables = VariableMapper.auto_populate_variables(job_application)

      # Should use French title since job seeker's locale matches job posting languages
      assert variables["Title"] == "Madame"
    end

    test "priority 2: company admin locale matches when job seeker doesn't" do
      # Job seeker prefers Italian, company admin prefers German, job posting supports German/English
      job_seeker = user_fixture(%{gender: :male, locale: :it})
      company_admin = employer_user_fixture(%{locale: :de})
      company = company_fixture(company_admin)
      job_posting = job_posting_fixture(company, %{language: [:German, :English]})
      job_application = job_application_fixture(job_seeker, job_posting)

      variables = VariableMapper.auto_populate_variables(job_application)

      # Should use German title since company admin's locale matches job posting languages
      assert variables["Title"] == "Herr"
    end

    test "priority 3: job seeker locale as fallback" do
      # Job seeker prefers French, job posting has no language restrictions
      job_seeker = user_fixture(%{gender: :female, locale: :fr})
      company_admin = employer_user_fixture(%{locale: :de})
      company = company_fixture(company_admin)
      job_posting = job_posting_fixture(company, %{language: nil})
      job_application = job_application_fixture(job_seeker, job_posting)

      variables = VariableMapper.auto_populate_variables(job_application)

      # Should use French title as fallback to job seeker's preference
      assert variables["Title"] == "Madame"
    end

    test "priority 4: German as final fallback" do
      # Use German locale for both users but empty job posting languages to test fallback logic
      job_seeker = user_fixture(%{gender: :male, locale: :de})
      company_admin = employer_user_fixture(%{locale: :de})
      company = company_fixture(company_admin)
      job_posting = job_posting_fixture(company, %{language: []})
      job_application = job_application_fixture(job_seeker, job_posting)

      variables = VariableMapper.auto_populate_variables(job_application)

      # Should use German title as job seeker's preference (which is also the fallback)
      assert variables["Title"] == "Herr"
    end

    test "complex scenario with multiple languages" do
      # Job seeker prefers English, company admin prefers Italian, job posting supports French/Italian
      job_seeker = user_fixture(%{gender: :female, locale: :en})
      company_admin = employer_user_fixture(%{gender: :male, locale: :it})
      company = company_fixture(company_admin)
      job_posting = job_posting_fixture(company, %{language: [:French, :Italian]})
      job_application = job_application_fixture(job_seeker, job_posting)

      variables = VariableMapper.auto_populate_variables(job_application)

      # Should use Italian title since company admin's locale matches job posting languages
      # (job seeker's English is not in the supported languages)
      assert variables["Title"] == "Signora"
    end

    test "empty job posting language array uses job seeker preference" do
      job_seeker = user_fixture(%{gender: :male, locale: :fr})
      company_admin = employer_user_fixture(%{locale: :de})
      company = company_fixture(company_admin)
      job_posting = job_posting_fixture(company, %{language: []})
      job_application = job_application_fixture(job_seeker, job_posting)

      variables = VariableMapper.auto_populate_variables(job_application)

      # Should use French title as job seeker's preference
      assert variables["Title"] == "Monsieur"
    end
  end
end
