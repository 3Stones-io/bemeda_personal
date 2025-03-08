defmodule BemedaPersonalWeb.Resume.ShowLiveTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.ResumesFixtures

  alias BemedaPersonal.Repo
  alias BemedaPersonal.Resumes

  # Consolidated setup function
  defp setup_resume_data(context) do
    # Convert list to map if needed
    context = if is_list(context), do: Map.new(context), else: context

    user = user_fixture(confirmed: true)
    resume = resume_fixture(user)
    resume_with_user = Repo.preload(resume, :user)

    # Create education if needed
    context_with_education =
      if context[:create_education] do
        education = education_fixture(resume)
        # Reload education with resume association preloaded
        education_with_resume =
          Resumes.Education
          |> Repo.get!(education.id)
          |> Repo.preload(:resume)

        Map.put(context, :education, education_with_resume)
      else
        context
      end

    # Create work experience if needed
    context_with_work_experience =
      if context_with_education[:create_work_experience] do
        work_experience = work_experience_fixture(resume)
        # Reload work experience with resume association preloaded
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
      assert html =~ resume.location
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

    test "can navigate to add education form", %{conn: conn, user: user} do
      {:ok, show_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      # Use a more specific selector for the Education Add button
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

      # After deletion, the education entry should not be present
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

      # Use a more specific selector for the Work Experience Add button
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

      # After deletion, the work experience entry should not be present
      refute render(show_live) =~ work_experience.company_name
      assert render(show_live) =~ "Work experience entry deleted"
    end
  end

  describe "/resume/:id" do
    setup [:setup_resume_data]

    test "shows public link when resume is public", %{conn: conn, user: user, resume: resume} do
      # Update resume to be public
      {:ok, resume} = Resumes.update_resume(resume, %{is_public: true})

      {:ok, _show_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      assert html =~ "Your resume is public"
      assert html =~ "/resume/#{resume.id}"
    end

    test "does not show public link when resume is private", %{
      conn: conn,
      user: user,
      resume: resume
    } do
      # Update resume to be private
      {:ok, _resume} = Resumes.update_resume(resume, %{is_public: false})

      {:ok, _show_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/resume")

      refute html =~ "Your resume is public"
    end

    test "can view public resume", %{conn: conn, resume: resume} do
      # Update resume to be public
      {:ok, resume} = Resumes.update_resume(resume, %{is_public: true})

      # Access the public resume directly without logging in
      {:ok, _public_live, html} = live(conn, ~p"/resume/#{resume.id}")

      assert html =~ resume.headline
    end
  end
end
