defmodule BemedaPersonal.ResumesTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.ResumesFixtures

  alias BemedaPersonal.Resumes
  alias BemedaPersonal.Resumes.Education
  alias BemedaPersonal.Resumes.Resume
  alias BemedaPersonal.Resumes.WorkExperience

  describe "get_or_create_resume_by_user/1" do
    test "returns existing resume" do
      user = user_fixture()
      resume = resume_fixture(user)

      assert %Resume{id: id} = Resumes.get_or_create_resume_by_user(user)
      assert id == resume.id
    end

    test "creates resume if none exists" do
      user = user_fixture()

      assert %Resume{} = resume = Resumes.get_or_create_resume_by_user(user)
      assert resume.user_id == user.id
    end
  end

  describe "get_resume/1" do
    test "returns the resume with given id" do
      user = user_fixture()
      resume = resume_fixture(user)

      fetched_resume = Resumes.get_resume(resume.id)
      assert fetched_resume.id == resume.id
      assert fetched_resume.headline == resume.headline
    end

    test "returns nil if resume doesn't exist" do
      assert Resumes.get_resume(Ecto.UUID.generate()) == nil
    end
  end

  describe "update_resume/2" do
    test "with valid data updates the resume" do
      user = user_fixture()
      resume = resume_fixture(user)
      update_attrs = %{headline: "Updated Headline", summary: "Updated Summary"}

      assert {:ok, %Resume{} = updated_resume} = Resumes.update_resume(resume, update_attrs)
      assert updated_resume.headline == "Updated Headline"
      assert updated_resume.summary == "Updated Summary"
    end

    test "with invalid data returns error changeset" do
      user = user_fixture()
      resume = resume_fixture(user)

      # Create another user and resume to test uniqueness constraint
      other_user = user_fixture()
      _other_resume = resume_fixture(other_user)

      # Try to update resume with another user's ID (which should fail due to unique constraint)
      assert {:error, %Ecto.Changeset{}} =
               Resumes.update_resume(resume, %{user_id: other_user.id})

      # Verify the resume wasn't changed
      fetched_resume = Resumes.get_resume(resume.id)
      assert fetched_resume.id == resume.id
      assert fetched_resume.headline == resume.headline
    end
  end

  describe "change_resume/1" do
    test "returns a resume changeset" do
      user = user_fixture()
      resume = resume_fixture(user)

      assert %Ecto.Changeset{} = Resumes.change_resume(resume)
    end
  end

  describe "change_resume/2" do
    test "returns a resume changeset with changes applied" do
      user = user_fixture()
      resume = resume_fixture(user)

      assert %Ecto.Changeset{changes: %{headline: "New Headline"}} =
               Resumes.change_resume(resume, %{headline: "New Headline"})
    end
  end

  describe "list_educations/1" do
    setup do
      user = user_fixture()
      resume = resume_fixture(user)
      education = education_fixture(resume)

      %{user: user, resume: resume, education: education}
    end

    test "returns all educations for a resume", %{resume: resume, education: education} do
      educations = Resumes.list_educations(resume.id)
      assert length(educations) == 1
      assert hd(educations).id == education.id
    end

    test "orders by current and start_date", %{resume: resume, education: education} do
      # Create a current education with an earlier start date
      current_education = education_fixture(resume, %{current: true, start_date: ~D[2010-01-01]})

      # Create another non-current education with a later start date
      newer_education = education_fixture(resume, %{start_date: ~D[2020-01-01]})

      educations = Resumes.list_educations(resume.id)

      # Current education should be first, then ordered by start_date (desc)
      assert Enum.map(educations, & &1.id) == [
               current_education.id,
               newer_education.id,
               education.id
             ]
    end
  end

  describe "get_education!/1" do
    setup do
      user = user_fixture()
      resume = resume_fixture(user)
      education = education_fixture(resume)

      %{education: education}
    end

    test "returns the education with given id", %{education: education} do
      fetched_education = Resumes.get_education!(education.id)
      assert fetched_education.id == education.id
      assert fetched_education.institution == education.institution
      assert fetched_education.degree == education.degree
    end

    test "raises if education doesn't exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Resumes.get_education!(Ecto.UUID.generate())
      end
    end
  end

  describe "create_or_update_education/3" do
    setup do
      user = user_fixture()
      resume = resume_fixture(user)

      %{resume: resume}
    end

    test "with valid data creates a education", %{resume: resume} do
      attrs = %{
        institution: "University of Example",
        degree: "Bachelor of Science",
        field_of_study: "Computer Science",
        start_date: ~D[2015-09-01],
        end_date: ~D[2019-05-31],
        current: false,
        description: "Studied computer science with a focus on software engineering.",
        resume_id: resume.id
      }

      assert {:ok, %Education{} = education} =
               Resumes.create_or_update_education(%Education{}, resume, attrs)

      assert education.institution == attrs.institution
      assert education.degree == attrs.degree
      assert education.field_of_study == attrs.field_of_study
      assert education.start_date == attrs.start_date
      assert education.end_date == attrs.end_date
      assert education.current == attrs.current
      assert education.description == attrs.description
    end

    test "with valid data updates the education", %{resume: resume} do
      # Create a new education to update
      education_fixture = education_fixture(resume)
      update_attrs = %{institution: "Updated University", degree: "Updated Degree"}

      # Preload the resume association
      education_with_resume = Repo.preload(education_fixture, :resume)

      assert {:ok, %Education{} = updated_education} =
               Resumes.create_or_update_education(education_with_resume, resume, update_attrs)

      assert updated_education.institution == "Updated University"
      assert updated_education.degree == "Updated Degree"
    end

    test "with invalid data returns error changeset", %{resume: resume} do
      # Missing required field (institution)
      assert {:error, %Ecto.Changeset{}} =
               Resumes.create_or_update_education(%Education{}, resume, %{degree: "Some Degree"})
    end

    test "validates end date after start date", %{resume: resume} do
      invalid_attrs = %{
        institution: "Test University",
        start_date: ~D[2020-01-01],
        end_date: ~D[2019-01-01]
      }

      assert {:error, changeset} =
               Resumes.create_or_update_education(%Education{}, resume, invalid_attrs)

      assert "must be after or equal to start date" in errors_on(changeset).end_date
    end

    test "validates current education has no end date", %{resume: resume} do
      invalid_attrs = %{
        institution: "Test University",
        current: true,
        end_date: ~D[2022-01-01]
      }

      assert {:error, changeset} =
               Resumes.create_or_update_education(%Education{}, resume, invalid_attrs)

      assert "must be blank for current education" in errors_on(changeset).end_date
    end
  end

  describe "delete_education/1" do
    setup do
      user = user_fixture()
      resume = resume_fixture(user)
      education = education_fixture(resume)

      %{education: education}
    end

    test "deletes the education", %{education: education} do
      assert {:ok, %Education{}} = Resumes.delete_education(education)
      assert_raise Ecto.NoResultsError, fn -> Resumes.get_education!(education.id) end
    end
  end

  describe "change_education/1" do
    setup do
      user = user_fixture()
      resume = resume_fixture(user)
      education = education_fixture(resume)

      %{education: education}
    end

    test "returns a education changeset", %{education: education} do
      assert %Ecto.Changeset{} = Resumes.change_education(education)
    end
  end

  describe "change_education/2" do
    setup do
      user = user_fixture()
      resume = resume_fixture(user)
      education = education_fixture(resume)

      %{education: education}
    end

    test "returns a education changeset with changes applied", %{education: education} do
      assert %Ecto.Changeset{changes: %{institution: "New Institution"}} =
               Resumes.change_education(education, %{institution: "New Institution"})
    end
  end

  describe "list_work_experiences/1" do
    setup do
      user = user_fixture()
      resume = resume_fixture(user)
      work_experience = work_experience_fixture(resume)

      %{resume: resume, work_experience: work_experience}
    end

    test "returns all work_experiences for a resume", %{
      resume: resume,
      work_experience: work_experience
    } do
      work_experiences = Resumes.list_work_experiences(resume.id)
      assert length(work_experiences) == 1
      assert hd(work_experiences).id == work_experience.id
    end

    test "orders by current and start_date", %{resume: resume, work_experience: work_experience} do
      # Create a current work experience with an earlier start date
      current_work = work_experience_fixture(resume, %{current: true, start_date: ~D[2010-01-01]})

      # Create another non-current work experience with a later start date
      newer_work = work_experience_fixture(resume, %{start_date: ~D[2020-01-01]})

      work_experiences = Resumes.list_work_experiences(resume.id)

      # Current work should be first, then ordered by start_date (desc)
      assert Enum.map(work_experiences, & &1.id) == [
               current_work.id,
               newer_work.id,
               work_experience.id
             ]
    end
  end

  describe "get_work_experience!/1" do
    setup do
      user = user_fixture()
      resume = resume_fixture(user)
      work_experience = work_experience_fixture(resume)

      %{work_experience: work_experience}
    end

    test "returns the work_experience with given id", %{work_experience: work_experience} do
      fetched_work_experience = Resumes.get_work_experience!(work_experience.id)
      assert fetched_work_experience.id == work_experience.id
      assert fetched_work_experience.company_name == work_experience.company_name
      assert fetched_work_experience.title == work_experience.title
    end

    test "raises if work_experience doesn't exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Resumes.get_work_experience!(Ecto.UUID.generate())
      end
    end
  end

  describe "create_or_update_work_experience/3" do
    setup do
      user = user_fixture()
      resume = resume_fixture(user)

      %{resume: resume}
    end

    test "with valid data creates a work_experience", %{resume: resume} do
      attrs = %{
        company_name: "Example Corp",
        title: "Software Engineer",
        location: "New York, NY",
        start_date: ~D[2019-06-01],
        end_date: ~D[2022-12-31],
        current: false,
        description: "Developed web applications using Elixir and Phoenix.",
        resume_id: resume.id
      }

      assert {:ok, %WorkExperience{} = work_experience} =
               Resumes.create_or_update_work_experience(%WorkExperience{}, resume, attrs)

      assert work_experience.company_name == attrs.company_name
      assert work_experience.title == attrs.title
      assert work_experience.location == attrs.location
      assert work_experience.start_date == attrs.start_date
      assert work_experience.end_date == attrs.end_date
      assert work_experience.current == attrs.current
      assert work_experience.description == attrs.description
    end

    test "with valid data updates the work_experience", %{resume: resume} do
      # Create a new work experience to update
      work_experience_fixture = work_experience_fixture(resume)
      update_attrs = %{company_name: "Updated Company", title: "Updated Title"}

      # Preload the resume association
      work_experience_with_resume = Repo.preload(work_experience_fixture, :resume)

      assert {:ok, %WorkExperience{} = updated_work_experience} =
               Resumes.create_or_update_work_experience(
                 work_experience_with_resume,
                 resume,
                 update_attrs
               )

      assert updated_work_experience.company_name == "Updated Company"
      assert updated_work_experience.title == "Updated Title"
    end

    test "with invalid data returns error changeset", %{resume: resume} do
      # Missing required fields (company_name, title, start_date)
      assert {:error, %Ecto.Changeset{}} =
               Resumes.create_or_update_work_experience(%WorkExperience{}, resume, %{
                 location: "Some Location"
               })
    end

    test "validates end date after start date", %{resume: resume} do
      invalid_attrs = %{
        company_name: "Test Company",
        title: "Test Title",
        start_date: ~D[2020-01-01],
        end_date: ~D[2019-01-01]
      }

      assert {:error, changeset} =
               Resumes.create_or_update_work_experience(%WorkExperience{}, resume, invalid_attrs)

      assert "must be after or equal to start date" in errors_on(changeset).end_date
    end

    test "validates current job has no end date", %{resume: resume} do
      invalid_attrs = %{
        company_name: "Test Company",
        title: "Test Title",
        start_date: ~D[2020-01-01],
        current: true,
        end_date: ~D[2022-01-01]
      }

      assert {:error, changeset} =
               Resumes.create_or_update_work_experience(%WorkExperience{}, resume, invalid_attrs)

      assert "must be blank for current job" in errors_on(changeset).end_date
    end
  end

  describe "delete_work_experience/1" do
    setup do
      user = user_fixture()
      resume = resume_fixture(user)
      work_experience = work_experience_fixture(resume)

      %{work_experience: work_experience}
    end

    test "deletes the work_experience", %{work_experience: work_experience} do
      assert {:ok, %WorkExperience{}} = Resumes.delete_work_experience(work_experience)
      assert_raise Ecto.NoResultsError, fn -> Resumes.get_work_experience!(work_experience.id) end
    end
  end

  describe "change_work_experience/1" do
    setup do
      user = user_fixture()
      resume = resume_fixture(user)
      work_experience = work_experience_fixture(resume)

      %{work_experience: work_experience}
    end

    test "returns a work_experience changeset", %{work_experience: work_experience} do
      assert %Ecto.Changeset{} = Resumes.change_work_experience(work_experience)
    end
  end

  describe "change_work_experience/2" do
    setup do
      user = user_fixture()
      resume = resume_fixture(user)
      work_experience = work_experience_fixture(resume)

      %{work_experience: work_experience}
    end

    test "returns a work_experience changeset with changes applied", %{
      work_experience: work_experience
    } do
      assert %Ecto.Changeset{changes: %{company_name: "New Company"}} =
               Resumes.change_work_experience(work_experience, %{company_name: "New Company"})
    end
  end
end
