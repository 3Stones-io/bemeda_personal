defmodule BemedaPersonalWeb.Resume.ShowLiveTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.ResumesFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Repo
  alias BemedaPersonal.Resumes

  defp setup_resume_data(context) do
    context = if is_list(context), do: Map.new(context), else: context

    user = user_fixture(confirmed: true)
    scope = Scope.for_user(user)
    resume = resume_fixture(scope)
    resume_with_user = Repo.preload(resume, :user)

    context_with_education =
      if context[:create_education] do
        education = education_fixture(scope, resume)

        education_with_resume =
          Resumes.Education
          |> Repo.get!(education.id)
          |> Repo.preload(:resume)

        Map.put(context, :education, education_with_resume)
      else
        context
      end

    context_with_work_experience =
      if context_with_education[:create_work_experience] do
        work_experience = work_experience_fixture(scope, resume)

        work_experience_with_resume =
          Resumes.WorkExperience
          |> Repo.get!(work_experience.id)
          |> Repo.preload(:resume)

        Map.put(context_with_education, :work_experience, work_experience_with_resume)
      else
        context_with_education
      end

    Map.merge(context_with_work_experience, %{user: user, resume: resume_with_user})
  end

  describe "/resume" do
    setup [:setup_resume_data]

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/resume")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "renders resume page with user data", %{conn: conn, user: user, resume: resume} do
      {:ok, _show_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert html =~ "My Resume"
      assert html =~ resume.headline
      assert html =~ resume.summary
    end

    test "can navigate to edit resume form", %{conn: conn, user: user} do
      {:ok, show_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert {:error, {:live_redirect, %{to: path}}} =
               show_live
               |> element("a", "Edit")
               |> render_click()

      assert path == ~p"/resume/edit"
    end
  end

  describe "/resume/education" do
    setup do
      setup_resume_data(%{create_education: true})
    end

    test "renders education entries", %{conn: conn, user: user, education: education} do
      {:ok, _show_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert html =~ "Education"
      assert html =~ education.institution
      assert html =~ education.degree
      assert html =~ education.field_of_study
    end

    test "shows public link when resume is public", %{conn: conn, user: user, resume: resume} do
      scope = Scope.for_user(user)
      {:ok, resume} = Resumes.update_resume(scope, resume, %{is_public: true})

      {:ok, _show_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert html =~ "Your resume is public"
      assert html =~ "/resumes/#{resume.id}"
    end

    test "does not show public link when resume is private", %{
      conn: conn,
      user: user,
      resume: resume
    } do
      scope = Scope.for_user(user)
      {:ok, _resume} = Resumes.update_resume(scope, resume, %{is_public: false})

      {:ok, _show_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      refute html =~ "Your resume is public"
    end

    test "can view public resume", %{conn: conn, resume: resume, user: user} do
      scope = Scope.for_user(user)
      {:ok, resume} = Resumes.update_resume(scope, resume, %{is_public: true})

      {:ok, _public_live, html} = live(conn, ~p"/resumes/#{resume.id}")

      assert html =~ resume.headline
    end

    test "can navigate to add education form", %{conn: conn, user: user} do
      {:ok, show_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert {:error, {:live_redirect, %{to: path}}} =
               show_live
               |> element("a[href='/resume/education/new']")
               |> render_click()

      assert path == ~p"/resume/education/new"
    end

    test "can navigate to edit education form", %{conn: conn, user: user, education: education} do
      {:ok, show_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert {:error, {:live_redirect, %{to: path}}} =
               show_live
               |> element("a[href*='education/#{education.id}/edit']")
               |> render_click()

      assert path == ~p"/resume/education/#{education.id}/edit"
    end

    test "can delete education entry", %{conn: conn, user: user, education: education} do
      {:ok, show_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert show_live
             |> element("#delete-education-#{education.id}")
             |> render_click()

      refute render(show_live) =~ education.institution
      assert render(show_live) =~ "Education entry deleted"
    end
  end

  describe "/resume/work-experience" do
    setup do
      setup_resume_data(%{create_work_experience: true})
    end

    test "renders work experience entries", %{
      conn: conn,
      user: user,
      work_experience: work_experience
    } do
      {:ok, _show_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert html =~ "Work Experience"
      assert html =~ work_experience.company_name
      assert html =~ work_experience.title
      assert html =~ work_experience.location
    end

    test "can navigate to add work experience form", %{conn: conn, user: user} do
      {:ok, show_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert {:error, {:live_redirect, %{to: path}}} =
               show_live
               |> element("a[href='/resume/work-experience/new']")
               |> render_click()

      assert path == ~p"/resume/work-experience/new"
    end

    test "can navigate to edit work experience form", %{
      conn: conn,
      user: user,
      work_experience: work_experience
    } do
      {:ok, show_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert {:error, {:live_redirect, %{to: path}}} =
               show_live
               |> element("a[href*='work-experience/#{work_experience.id}/edit']")
               |> render_click()

      assert path == ~p"/resume/work-experience/#{work_experience.id}/edit"
    end

    test "can delete work experience entry", %{
      conn: conn,
      user: user,
      work_experience: work_experience
    } do
      {:ok, show_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert show_live
             |> element("#delete-work-experience-#{work_experience.id}")
             |> render_click()

      refute render(show_live) =~ work_experience.company_name
      assert render(show_live) =~ "Work experience entry deleted"
    end
  end

  describe "/resume/edit" do
    setup [:setup_resume_data]

    test "user can update a resume", %{conn: conn, user: user, resume: _resume} do
      # Navigate to the edit resume form
      {:ok, show_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert {:error, {:live_redirect, %{to: path}}} =
               show_live
               |> element("a", "Edit")
               |> render_click()

      assert path == ~p"/resume/edit"

      # Submit the form with updated data
      {:ok, edit_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume/edit")

      updated_headline = "Senior Software Engineer"
      updated_summary = "Experienced software engineer with a passion for Elixir and Phoenix."

      assert edit_live
             |> form("#resume-form", %{
               "resume" => %{
                 "headline" => updated_headline,
                 "summary" => updated_summary
               }
             })
             |> render_submit()

      # Verify the resume was updated
      {:ok, _show_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert html =~ updated_headline
      assert html =~ updated_summary
    end
  end

  describe "/resume/education/new" do
    setup [:setup_resume_data]

    test "user can create a new education entry", %{conn: conn, user: user} do
      # Navigate to the new education form
      {:ok, show_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert {:error, {:live_redirect, %{to: path}}} =
               show_live
               |> element("a[href='/resume/education/new']")
               |> render_click()

      assert path == ~p"/resume/education/new"

      # Submit the form with new education data
      {:ok, new_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume/education/new")

      institution = "Harvard University"
      degree = "Master of Science"
      field_of_study = "Data Science"

      assert new_live
             |> form("#education-form", %{
               "education" => %{
                 "institution" => institution,
                 "degree" => degree,
                 "field_of_study" => field_of_study,
                 "start_date" => "2020-09-01",
                 "end_date" => "2022-05-31",
                 "current" => false,
                 "description" => "Studied data science with a focus on machine learning."
               }
             })
             |> render_submit()

      # Verify the education entry was created
      {:ok, _show_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert html =~ institution
      assert html =~ degree
      assert html =~ field_of_study
    end

    test "renders errors when education data is invalid", %{conn: conn, user: user} do
      {:ok, new_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume/education/new")

      # Try to submit the form with invalid data (missing required fields)
      result =
        new_live
        |> form("#education-form", %{
          "education" => %{
            "institution" => "",
            "start_date" => ""
          }
        })
        |> render_change()

      # Verify error messages are displayed
      assert result =~ "can&#39;t be blank"
    end
  end

  describe "/resume/education/:id/edit" do
    setup [:setup_resume_data]

    test "user can update an existing education entry", %{conn: conn, user: user} do
      # Create an education entry first
      scope = Scope.for_user(user)
      resume = Resumes.get_or_create_resume_by_user(scope)
      education = education_fixture(scope, resume)

      # Navigate to the edit education form
      {:ok, show_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert {:error, {:live_redirect, %{to: path}}} =
               show_live
               |> element("a[href*='education/#{education.id}/edit']")
               |> render_click()

      assert path == ~p"/resume/education/#{education.id}/edit"

      # Submit the form with updated education data
      {:ok, edit_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume/education/#{education.id}/edit")

      updated_institution = "MIT"
      updated_degree = "PhD"
      updated_field_of_study = "Artificial Intelligence"

      assert edit_live
             |> form("#education-form", %{
               "education" => %{
                 "institution" => updated_institution,
                 "degree" => updated_degree,
                 "field_of_study" => updated_field_of_study,
                 "start_date" => "2018-09-01",
                 "end_date" => "2023-05-31",
                 "current" => false,
                 "description" => "Advanced research in AI and machine learning."
               }
             })
             |> render_submit()

      # Verify the education entry was updated
      {:ok, _show_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert html =~ updated_institution
      assert html =~ updated_degree
      assert html =~ updated_field_of_study
    end
  end

  describe "/resume/work-experience/new" do
    setup [:setup_resume_data]

    test "user can create a new work_experience record", %{conn: conn, user: user} do
      # Navigate to the new work experience form
      {:ok, show_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert {:error, {:live_redirect, %{to: path}}} =
               show_live
               |> element("a[href='/resume/work-experience/new']")
               |> render_click()

      assert path == ~p"/resume/work-experience/new"

      # Submit the form with new work experience data
      {:ok, new_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume/work-experience/new")

      company_name = "Google"
      title = "Senior Software Engineer"
      location = "Mountain View, CA"

      assert new_live
             |> form("#work-experience-form", %{
               "work_experience" => %{
                 "company_name" => company_name,
                 "title" => title,
                 "location" => location,
                 "start_date" => "2020-01-01",
                 "end_date" => "2023-12-31",
                 "current" => false,
                 "description" => "Developed web applications using Elixir and Phoenix."
               }
             })
             |> render_submit()

      # Verify the work experience entry was created
      {:ok, _show_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert html =~ company_name
      assert html =~ title
      assert html =~ location
    end

    test "renders errors when work experience data is invalid", %{conn: conn, user: user} do
      {:ok, new_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume/work-experience/new")

      # Try to submit the form with invalid data (missing required fields)
      result =
        new_live
        |> form("#work-experience-form", %{
          "work_experience" => %{
            "company_name" => "",
            "title" => "",
            "start_date" => ""
          }
        })
        |> render_change()

      # Verify error messages are displayed
      assert result =~ "can&#39;t be blank"
    end
  end

  describe "/resume/work-experience/:id/edit" do
    setup [:setup_resume_data]

    test "user can update an existing work_experience record", %{conn: conn, user: user} do
      # Create a work experience entry first
      scope = Scope.for_user(user)
      resume = Resumes.get_or_create_resume_by_user(scope)
      work_experience = work_experience_fixture(scope, resume)

      # Navigate to the edit work experience form
      {:ok, show_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert {:error, {:live_redirect, %{to: path}}} =
               show_live
               |> element("a[href*='work-experience/#{work_experience.id}/edit']")
               |> render_click()

      assert path == ~p"/resume/work-experience/#{work_experience.id}/edit"

      # Submit the form with updated work experience data
      {:ok, edit_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume/work-experience/#{work_experience.id}/edit")

      updated_company_name = "Microsoft"
      updated_title = "Principal Engineer"
      updated_location = "Seattle, WA"

      assert edit_live
             |> form("#work-experience-form", %{
               "work_experience" => %{
                 "company_name" => updated_company_name,
                 "title" => updated_title,
                 "location" => updated_location,
                 "start_date" => "2018-01-01",
                 "end_date" => "2022-12-31",
                 "current" => false,
                 "description" => "Led development of cloud-based solutions."
               }
             })
             |> render_submit()

      # Verify the work experience entry was updated
      {:ok, _show_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert html =~ updated_company_name
      assert html =~ updated_title
      assert html =~ updated_location
    end
  end
end
