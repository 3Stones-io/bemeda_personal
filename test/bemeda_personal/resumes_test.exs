defmodule BemedaPersonal.ResumesTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures, only: [user_scope_fixture: 0]
  import BemedaPersonal.ResumesFixtures

  alias BemedaPersonal.Resumes
  alias BemedaPersonal.Resumes.Education
  alias BemedaPersonal.Resumes.Resume
  alias BemedaPersonal.Resumes.WorkExperience
  alias BemedaPersonalWeb.Endpoint

  # Helper function to receive PubSub messages while ignoring email messages
  defp assert_receive_pubsub_message(timeout \\ 100) do
    receive do
      {:email, _email} ->
        # Skip email messages and keep waiting for PubSub message
        assert_receive_pubsub_message(timeout)

      msg ->
        # Return any non-email message (should be PubSub)
        msg
    after
      timeout ->
        flunk("No PubSub message received within #{timeout}ms")
    end
  end

  describe "get_or_create_resume_by_user/1" do
    test "returns existing resume" do
      scope = user_scope_fixture()
      resume = resume_fixture(scope)

      assert %Resume{id: id} = Resumes.get_or_create_resume_by_user(scope)
      assert id == resume.id
    end

    test "creates resume if none exists" do
      scope = user_scope_fixture()

      assert %Resume{} = resume = Resumes.get_or_create_resume_by_user(scope)
      assert resume.user_id == scope.user.id
    end

    test "broadcasts resume update event" do
      scope = user_scope_fixture()

      resume = Resumes.get_or_create_resume_by_user(scope)

      new_scope = user_scope_fixture()
      topic = "user:#{new_scope.user.id}:resumes"
      Endpoint.subscribe(topic)

      new_resume = Resumes.get_or_create_resume_by_user(new_scope)

      received_message = assert_receive_pubsub_message()

      assert received_message == {:created, new_resume}

      # Subscribe to the first scope's topic for the update broadcast
      first_topic = "user:#{scope.user.id}:resumes"
      Endpoint.subscribe(first_topic)

      {:ok, updated_resume} =
        Resumes.update_resume(scope, resume, %{headline: "Updated Headline"})

      received_update_message = assert_receive_pubsub_message()
      assert received_update_message == {:updated, updated_resume}
    end
  end

  describe "get_resume/1" do
    test "returns the resume with given id" do
      scope = user_scope_fixture()
      resume = resume_fixture(scope)

      fetched_resume = Resumes.get_resume!(scope, resume.id)
      assert fetched_resume.id == resume.id
      assert fetched_resume.headline == resume.headline

      assert Ecto.assoc_loaded?(fetched_resume.user)
      assert Ecto.assoc_loaded?(fetched_resume.educations)
      assert Ecto.assoc_loaded?(fetched_resume.work_experiences)
    end

    test "returns nil if resume doesn't exist" do
      scope = user_scope_fixture()

      assert_raise Ecto.NoResultsError, fn ->
        Resumes.get_resume!(scope, Ecto.UUID.generate())
      end
    end
  end

  describe "update_resume/2" do
    test "with valid data updates the resume" do
      scope = user_scope_fixture()
      resume = resume_fixture(scope)
      update_attrs = %{headline: "Updated Headline", summary: "Updated Summary"}

      assert {:ok, %Resume{} = updated_resume} =
               Resumes.update_resume(scope, resume, update_attrs)

      assert updated_resume.headline == "Updated Headline"
      assert updated_resume.summary == "Updated Summary"
    end

    test "with invalid data returns error changeset" do
      scope = user_scope_fixture()
      resume = resume_fixture(scope)

      {:ok, _updated_resume} = Resumes.update_resume(scope, resume, %{headline: "New Headline"})

      fetched_resume = Resumes.get_resume!(scope, resume.id)
      assert fetched_resume.id == resume.id
      assert fetched_resume.headline == "New Headline"
    end

    test "broadcasts resume update event" do
      scope = user_scope_fixture()
      resume = resume_fixture(scope)

      topic = "user:#{scope.user.id}:resumes"
      Endpoint.subscribe(topic)

      {:ok, updated_resume} =
        Resumes.update_resume(scope, resume, %{headline: "Updated Headline"})

      received_message = assert_receive_pubsub_message()
      assert received_message == {:updated, updated_resume}
    end
  end

  describe "change_resume/1" do
    test "returns a resume changeset" do
      scope = user_scope_fixture()
      resume = resume_fixture(scope)

      assert %Ecto.Changeset{} = Resumes.change_resume(scope, resume)
    end

    test "returns a resume changeset with changes applied" do
      scope = user_scope_fixture()
      resume = resume_fixture(scope)

      assert %Ecto.Changeset{changes: %{headline: "New Headline"}} =
               Resumes.change_resume(scope, resume, %{headline: "New Headline"})
    end
  end

  describe "list_educations/1" do
    setup do
      scope = user_scope_fixture()
      resume = resume_fixture(scope)
      education = education_fixture(scope, resume)

      %{scope: scope, resume: resume, education: education}
    end

    test "returns all educations for a resume", %{resume: resume, education: education} do
      educations = Resumes.list_educations(resume.id)
      assert length(educations) == 1
      assert hd(educations).id == education.id

      Enum.each(educations, fn education ->
        assert Ecto.assoc_loaded?(education.resume)
      end)
    end

    test "orders by current and start_date", %{scope: scope, resume: resume, education: education} do
      newer_education =
        education_fixture(scope, resume, %{start_date: ~D[2010-01-01], end_date: ~D[2014-01-01]})

      current_education =
        education_fixture(scope, resume, %{
          start_date: ~D[2020-01-01],
          end_date: nil,
          current: true
        })

      educations = Resumes.list_educations(resume.id)

      assert Enum.map(educations, & &1.id) == [
               current_education.id,
               education.id,
               newer_education.id
             ]
    end

    test "returns an empty list for a non-existent resume ID" do
      non_existent_id = Ecto.UUID.generate()

      assert non_existent_id
             |> Resumes.list_educations()
             |> Enum.empty?()
    end
  end

  describe "get_education/1" do
    setup do
      scope = user_scope_fixture()
      resume = resume_fixture(scope)
      education = education_fixture(scope, resume)

      %{education: education}
    end

    test "returns the education with given id", %{education: education} do
      fetched_education = Resumes.get_education(education.id)
      assert fetched_education.id == education.id
      assert fetched_education.institution == education.institution
      assert fetched_education.degree == education.degree

      assert Ecto.assoc_loaded?(fetched_education.resume)
    end

    test "returns nil if education doesn't exist" do
      refute Resumes.get_education(Ecto.UUID.generate())
    end
  end

  describe "get_education!/2" do
    setup do
      scope = user_scope_fixture()
      resume = resume_fixture(scope)
      education = education_fixture(scope, resume)

      %{scope: scope, education: education}
    end

    test "returns the education with given id", %{scope: scope, education: education} do
      fetched_education = Resumes.get_education!(scope, education.id)
      assert fetched_education.id == education.id
      assert fetched_education.institution == education.institution
      assert fetched_education.degree == education.degree

      assert Ecto.assoc_loaded?(fetched_education.resume)
    end

    test "raises if education doesn't exist" do
      scope = user_scope_fixture()

      assert_raise Ecto.NoResultsError, fn ->
        Resumes.get_education!(scope, Ecto.UUID.generate())
      end
    end

    test "raises if education belongs to different user" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      other_resume = resume_fixture(other_scope)
      other_education = education_fixture(other_scope, other_resume)

      assert_raise Ecto.NoResultsError, fn ->
        Resumes.get_education!(scope, other_education.id)
      end
    end
  end

  describe "create_or_update_education/3" do
    setup do
      scope = user_scope_fixture()
      resume = resume_fixture(scope)

      %{scope: scope, resume: resume}
    end

    test "with valid data creates a education", %{scope: scope, resume: resume} do
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
               Resumes.create_or_update_education(scope, %Education{}, resume, attrs)

      assert education.institution == attrs.institution
      assert education.degree == attrs.degree
      assert education.field_of_study == attrs.field_of_study
      assert education.start_date == attrs.start_date
      assert education.end_date == attrs.end_date
      assert education.current == attrs.current
      assert education.description == attrs.description
    end

    test "with valid data updates the education", %{scope: scope, resume: resume} do
      education_fixture = education_fixture(scope, resume)
      update_attrs = %{institution: "Updated University", degree: "Updated Degree"}

      education_with_resume = Repo.preload(education_fixture, :resume)

      assert {:ok, %Education{} = updated_education} =
               Resumes.create_or_update_education(
                 scope,
                 education_with_resume,
                 resume,
                 update_attrs
               )

      assert updated_education.institution == "Updated University"
      assert updated_education.degree == "Updated Degree"
    end

    test "with invalid data returns error changeset", %{scope: scope, resume: resume} do
      assert {:error, %Ecto.Changeset{}} =
               Resumes.create_or_update_education(scope, %Education{}, resume, %{
                 degree: "Some Degree"
               })
    end

    test "validates end date after start date", %{scope: scope, resume: resume} do
      invalid_attrs = %{
        institution: "Test University",
        start_date: ~D[2020-01-01],
        end_date: ~D[2019-01-01]
      }

      assert {:error, changeset} =
               Resumes.create_or_update_education(scope, %Education{}, resume, invalid_attrs)

      assert "end date must be after or equal to start date" in errors_on(changeset).end_date
    end

    test "validates current education has no end date", %{scope: scope, resume: resume} do
      invalid_attrs = %{
        institution: "Test University",
        current: true,
        end_date: ~D[2022-01-01]
      }

      assert {:error, changeset} =
               Resumes.create_or_update_education(scope, %Education{}, resume, invalid_attrs)

      assert "end date must be blank for current education" in errors_on(changeset).end_date
    end

    test "either current is set or an end date is set", %{scope: scope, resume: resume} do
      base_attrs = %{
        institution: "Test University",
        degree: "Test Degree",
        field_of_study: "Test Field",
        start_date: ~D[2020-01-01]
      }

      assert {:error, changeset} =
               Resumes.create_or_update_education(scope, %Education{}, resume, base_attrs)

      assert "either mark as current or provide an end date" in errors_on(changeset).end_date

      current_attrs = Map.put(base_attrs, :current, true)

      assert {:ok, %Education{} = education} =
               Resumes.create_or_update_education(scope, %Education{}, resume, current_attrs)

      assert education.current == true
      assert education.end_date == nil

      end_date_attrs = Map.put(base_attrs, :end_date, ~D[2024-01-01])

      assert {:ok, %Education{} = education} =
               Resumes.create_or_update_education(scope, %Education{}, resume, end_date_attrs)

      assert education.end_date == ~D[2024-01-01]
    end

    test "broadcasts education update event", %{scope: scope, resume: resume} do
      topic = "user:#{scope.user.id}:educations"
      Endpoint.subscribe(topic)

      attrs = %{
        institution: "University of Example",
        degree: "Bachelor of Science",
        field_of_study: "Computer Science",
        start_date: ~D[2015-09-01],
        end_date: ~D[2019-05-31]
      }

      {:ok, education} = Resumes.create_or_update_education(scope, %Education{}, resume, attrs)

      received_message = assert_receive_pubsub_message()
      assert received_message == {:created, education}
    end
  end

  describe "delete_education/1" do
    setup do
      scope = user_scope_fixture()
      resume = resume_fixture(scope)
      education = education_fixture(scope, resume)

      %{scope: scope, education: education, resume: resume}
    end

    test "deletes the education", %{scope: scope, education: education} do
      assert {:ok, %Education{}} = Resumes.delete_education(scope, education)

      assert_raise Ecto.NoResultsError, fn ->
        Resumes.get_education!(scope, education.id)
      end
    end

    test "broadcasts education delete event", %{
      scope: scope,
      education: education
    } do
      topic = "user:#{scope.user.id}:educations"
      Endpoint.subscribe(topic)

      {:ok, deleted_education} = Resumes.delete_education(scope, education)

      received_message = assert_receive_pubsub_message()
      assert received_message == {:deleted, deleted_education}
    end
  end

  describe "change_education/1" do
    setup do
      scope = user_scope_fixture()
      resume = resume_fixture(scope)
      education = education_fixture(scope, resume)

      %{education: education}
    end

    test "returns a education changeset", %{education: education} do
      assert %Ecto.Changeset{} = Resumes.change_education(education)
    end
  end

  describe "change_education/2" do
    setup do
      scope = user_scope_fixture()
      resume = resume_fixture(scope)
      education = education_fixture(scope, resume)

      %{education: education}
    end

    test "returns a education changeset with changes applied", %{education: education} do
      assert %Ecto.Changeset{changes: %{institution: "New Institution"}} =
               Resumes.change_education(education, %{institution: "New Institution"})
    end
  end

  describe "list_work_experiences/1" do
    setup do
      scope = user_scope_fixture()
      resume = resume_fixture(scope)
      work_experience = work_experience_fixture(scope, resume)

      %{scope: scope, resume: resume, work_experience: work_experience}
    end

    test "returns all work_experiences for a resume", %{
      resume: resume,
      work_experience: work_experience
    } do
      work_experiences = Resumes.list_work_experiences(resume.id)
      assert length(work_experiences) == 1
      assert hd(work_experiences).id == work_experience.id

      Enum.each(work_experiences, fn work_experience ->
        assert Ecto.assoc_loaded?(work_experience.resume)
      end)
    end

    test "orders by current and start_date", %{
      scope: scope,
      resume: resume,
      work_experience: work_experience
    } do
      current_work =
        work_experience_fixture(scope, resume, %{
          current: true,
          start_date: ~D[2010-01-01],
          end_date: nil
        })

      newer_work = work_experience_fixture(scope, resume, %{start_date: ~D[2020-01-01]})

      work_experiences = Resumes.list_work_experiences(resume.id)

      assert Enum.map(work_experiences, & &1.id) == [
               current_work.id,
               newer_work.id,
               work_experience.id
             ]
    end

    test "returns an empty list for a non-existent resume ID" do
      non_existent_id = Ecto.UUID.generate()

      assert non_existent_id
             |> Resumes.list_work_experiences()
             |> Enum.empty?()
    end
  end

  describe "get_work_experience/1" do
    setup do
      scope = user_scope_fixture()
      resume = resume_fixture(scope)
      work_experience = work_experience_fixture(scope, resume)

      %{work_experience: work_experience}
    end

    test "returns the work_experience with given id", %{work_experience: work_experience} do
      fetched_work_experience = Resumes.get_work_experience(work_experience.id)
      assert fetched_work_experience.id == work_experience.id
      assert fetched_work_experience.company_name == work_experience.company_name
      assert fetched_work_experience.title == work_experience.title

      assert Ecto.assoc_loaded?(fetched_work_experience.resume)
    end

    test "returns nil if work_experience doesn't exist" do
      refute Resumes.get_work_experience(Ecto.UUID.generate())
    end
  end

  describe "create_or_update_work_experience/3" do
    setup do
      scope = user_scope_fixture()
      resume = resume_fixture(scope)

      %{scope: scope, resume: resume}
    end

    test "with valid data creates a work_experience", %{scope: scope, resume: resume} do
      attrs = %{
        company_name: "Example Corp",
        title: "Software Engineer",
        start_date: ~D[2019-06-01],
        end_date: ~D[2022-12-31],
        current: false,
        description: "Developed web applications using Elixir and Phoenix.",
        resume_id: resume.id
      }

      assert {:ok, %WorkExperience{} = work_experience} =
               Resumes.create_or_update_work_experience(scope, %WorkExperience{}, resume, attrs)

      assert work_experience.company_name == attrs.company_name
      assert work_experience.title == attrs.title
      assert work_experience.start_date == attrs.start_date
      assert work_experience.end_date == attrs.end_date
      assert work_experience.current == attrs.current
      assert work_experience.description == attrs.description
    end

    test "with valid data updates the work_experience", %{scope: scope, resume: resume} do
      work_experience_fixture = work_experience_fixture(scope, resume)
      update_attrs = %{company_name: "Updated Company", title: "Updated Title"}

      work_experience_with_resume = Repo.preload(work_experience_fixture, :resume)

      assert {:ok, %WorkExperience{} = updated_work_experience} =
               Resumes.create_or_update_work_experience(
                 scope,
                 work_experience_with_resume,
                 resume,
                 update_attrs
               )

      assert updated_work_experience.company_name == "Updated Company"
      assert updated_work_experience.title == "Updated Title"
    end

    test "with invalid data returns error changeset", %{scope: scope, resume: resume} do
      assert {:error, %Ecto.Changeset{}} =
               Resumes.create_or_update_work_experience(scope, %WorkExperience{}, resume, %{})
    end

    test "validates end date after start date", %{scope: scope, resume: resume} do
      invalid_attrs = %{
        company_name: "Test Company",
        title: "Test Title",
        start_date: ~D[2020-01-01],
        end_date: ~D[2019-01-01]
      }

      assert {:error, changeset} =
               Resumes.create_or_update_work_experience(
                 scope,
                 %WorkExperience{},
                 resume,
                 invalid_attrs
               )

      assert "end date must be after or equal to start date" in errors_on(changeset).end_date
    end

    test "validates current job has no end date", %{scope: scope, resume: resume} do
      invalid_attrs = %{
        company_name: "Test Company",
        title: "Test Title",
        start_date: ~D[2020-01-01],
        current: true,
        end_date: ~D[2022-01-01]
      }

      assert {:error, changeset} =
               Resumes.create_or_update_work_experience(
                 scope,
                 %WorkExperience{},
                 resume,
                 invalid_attrs
               )

      assert "end date must be blank for current job" in errors_on(changeset).end_date
    end

    test "either current is set or an end date is set", %{scope: scope, resume: resume} do
      base_attrs = %{
        company_name: "Test Company",
        title: "Test Title",
        start_date: ~D[2020-01-01]
      }

      assert {:error, changeset} =
               Resumes.create_or_update_work_experience(
                 scope,
                 %WorkExperience{},
                 resume,
                 base_attrs
               )

      assert "either mark as current or provide an end date" in errors_on(changeset).end_date

      current_attrs = Map.put(base_attrs, :current, true)

      assert {:ok, %WorkExperience{} = work_experience} =
               Resumes.create_or_update_work_experience(
                 scope,
                 %WorkExperience{},
                 resume,
                 current_attrs
               )

      assert work_experience.current == true
      assert work_experience.end_date == nil

      end_date_attrs = Map.put(base_attrs, :end_date, ~D[2024-01-01])

      assert {:ok, %WorkExperience{} = work_experience} =
               Resumes.create_or_update_work_experience(
                 scope,
                 %WorkExperience{},
                 resume,
                 end_date_attrs
               )

      assert work_experience.end_date == ~D[2024-01-01]
    end

    test "broadcasts work experience update event", %{scope: scope, resume: resume} do
      topic = "user:#{scope.user.id}:work_experiences"
      Endpoint.subscribe(topic)

      attrs = %{
        company_name: "Example Corp",
        title: "Software Engineer",
        start_date: ~D[2020-01-01],
        end_date: ~D[2022-12-31]
      }

      {:ok, work_experience} =
        Resumes.create_or_update_work_experience(scope, %WorkExperience{}, resume, attrs)

      received_message = assert_receive_pubsub_message()
      assert received_message == {:created, work_experience}
    end
  end

  describe "delete_work_experience/1" do
    setup do
      scope = user_scope_fixture()
      resume = resume_fixture(scope)
      work_experience = work_experience_fixture(scope, resume)

      %{scope: scope, work_experience: work_experience, resume: resume}
    end

    test "deletes the work_experience", %{scope: scope, work_experience: work_experience} do
      assert {:ok, %WorkExperience{}} = Resumes.delete_work_experience(scope, work_experience)
      refute Resumes.get_work_experience(work_experience.id)
    end

    test "broadcasts work experience delete event", %{
      scope: scope,
      work_experience: work_experience
    } do
      topic = "user:#{scope.user.id}:work_experiences"
      Endpoint.subscribe(topic)

      {:ok, deleted_work_experience} = Resumes.delete_work_experience(scope, work_experience)

      received_message = assert_receive_pubsub_message()
      assert received_message == {:deleted, deleted_work_experience}
    end
  end

  describe "change_work_experience/1" do
    setup do
      scope = user_scope_fixture()
      resume = resume_fixture(scope)
      work_experience = work_experience_fixture(scope, resume)

      %{work_experience: work_experience}
    end

    test "returns a work_experience changeset", %{work_experience: work_experience} do
      assert %Ecto.Changeset{} = Resumes.change_work_experience(work_experience)
    end
  end

  describe "change_work_experience/2" do
    setup do
      scope = user_scope_fixture()
      resume = resume_fixture(scope)
      work_experience = work_experience_fixture(scope, resume)

      %{work_experience: work_experience}
    end

    test "returns a work_experience changeset with changes applied", %{
      work_experience: work_experience
    } do
      assert %Ecto.Changeset{changes: %{company_name: "New Company"}} =
               Resumes.change_work_experience(work_experience, %{company_name: "New Company"})
    end
  end

  describe "get_user_resume/1" do
    test "returns the resume for a given user" do
      scope = user_scope_fixture()
      resume = resume_fixture(scope)

      fetched_resume = Resumes.get_user_resume(scope.user)
      assert fetched_resume.id == resume.id
      assert fetched_resume.user_id == scope.user.id
    end

    test "returns nil if user doesn't have a resume" do
      scope = user_scope_fixture()
      refute Resumes.get_user_resume(scope.user)
    end
  end
end
