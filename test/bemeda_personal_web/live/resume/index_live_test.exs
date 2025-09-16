defmodule BemedaPersonalWeb.Resume.IndexLiveTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.ResumesFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts.Scope

  describe "/resumes/:id" do
    test "displays resume with all sections", %{conn: conn} do
      user = user_fixture(confirmed: true)
      scope = Scope.for_user(user)
      resume = resume_fixture(scope, %{is_public: true})
      education = education_fixture(scope, resume)
      work_experience = work_experience_fixture(scope, resume)

      {:ok, _public_live, html} = live(conn, ~p"/resumes/#{resume.id}")

      assert html =~ "Resume"
      assert html =~ resume.headline
      assert html =~ resume.summary

      assert html =~ "Education"
      assert html =~ education.institution
      assert html =~ education.degree
      assert html =~ education.field_of_study

      assert html =~ "Work Experience"
      assert html =~ work_experience.company_name
      assert html =~ work_experience.title
      assert html =~ work_experience.location

      assert html =~ resume.contact_email
      assert html =~ resume.phone_number
      assert html =~ resume.website_url

      refute html =~ "Edit"
      refute html =~ "Delete"
    end

    test "displays resume with empty education and work experience sections", %{conn: conn} do
      user = user_fixture(confirmed: true)
      scope = Scope.for_user(user)
      resume = resume_fixture(scope, %{is_public: true})

      {:ok, _public_live, html} = live(conn, ~p"/resumes/#{resume.id}")

      assert html =~ "No education entries available."
      assert html =~ "No work experience entries available."
    end

    test "handles missing optional fields gracefully", %{conn: conn} do
      user = user_fixture(confirmed: true)
      scope = Scope.for_user(user)

      resume =
        resume_fixture(scope, %{
          is_public: true,
          headline: nil,
          summary: nil,
          contact_email: nil,
          phone_number: nil,
          website_url: nil
        })

      {:ok, _public_live, html} = live(conn, ~p"/resumes/#{resume.id}")

      assert html =~ "Professional"
      assert html =~ "No summary provided"
      assert html =~ "Email not provided"
      assert html =~ "Phone not specified"
      assert html =~ "Website not specified"
    end

    test "shows 404 when resume does not exist", %{conn: conn} do
      {:ok, _public_live, html} = live(conn, ~p"/resumes/#{Ecto.UUID.generate()}")

      assert html =~ "404"
      assert html =~ "Resume Not Found"
      assert html =~ "doesn&#39;t exist or is not available"
    end

    test "shows 404 when resume is not public", %{conn: conn} do
      user = user_fixture(confirmed: true)
      scope = Scope.for_user(user)
      resume = resume_fixture(scope, %{is_public: false})

      {:ok, _public_live, html} = live(conn, ~p"/resumes/#{resume.id}")

      assert html =~ "404"
      assert html =~ "Resume Not Found"
      assert html =~ "doesn&#39;t exist or is not available"
    end
  end

  describe "PubSub broadcast handling" do
    test "handles resume_updated broadcast when resume is public", %{conn: conn} do
      user = user_fixture(confirmed: true)
      scope = Scope.for_user(user)
      resume = resume_fixture(scope, %{is_public: true})

      {:ok, view, _html} = live(conn, ~p"/resumes/#{resume.id}")

      # Simulate a resume update broadcast
      updated_resume = %{resume | headline: "Updated Headline"}

      send(view.pid, {:updated, updated_resume})

      # Verify the resume was updated in the view
      assert render(view) =~ "Updated Headline"
    end

    test "handles resume_updated broadcast when resume becomes private", %{conn: conn} do
      user = user_fixture(confirmed: true)
      scope = Scope.for_user(user)
      resume = resume_fixture(scope, %{is_public: true})

      {:ok, view, _html} = live(conn, ~p"/resumes/#{resume.id}")

      # Simulate a resume update that makes it private
      private_resume = %{resume | is_public: false}

      send(view.pid, {:updated, private_resume})

      # Verify the view now shows 404
      assert render(view) =~ "404"
      assert render(view) =~ "Resume Not Found"
    end

    test "handles education_updated broadcast", %{conn: conn} do
      user = user_fixture(confirmed: true)
      scope = Scope.for_user(user)
      resume = resume_fixture(scope, %{is_public: true})

      {:ok, view, _html} = live(conn, ~p"/resumes/#{resume.id}")

      # Simulate an education update broadcast
      education = education_fixture(scope, resume, %{institution: "Test University"})

      send(view.pid, {:updated, education})

      # Verify the education appears in the view
      assert render(view) =~ "Test University"
    end

    test "handles education_deleted broadcast", %{conn: conn} do
      user = user_fixture(confirmed: true)
      scope = Scope.for_user(user)
      resume = resume_fixture(scope, %{is_public: true})
      education = education_fixture(scope, resume, %{institution: "Deleted University"})

      {:ok, view, _html} = live(conn, ~p"/resumes/#{resume.id}")

      # Verify education is initially present
      assert render(view) =~ "Deleted University"

      # Simulate an education deletion broadcast
      send(view.pid, {:deleted, education})

      # Verify the education is removed from the view
      refute render(view) =~ "Deleted University"
    end

    test "handles work_experience_updated broadcast", %{conn: conn} do
      user = user_fixture(confirmed: true)
      scope = Scope.for_user(user)
      resume = resume_fixture(scope, %{is_public: true})

      {:ok, view, _html} = live(conn, ~p"/resumes/#{resume.id}")

      # Simulate a work experience update broadcast
      work_experience = work_experience_fixture(scope, resume, %{company_name: "Test Company"})

      send(view.pid, {:updated, work_experience})

      # Verify the work experience appears in the view
      assert render(view) =~ "Test Company"
    end

    test "handles work_experience_deleted broadcast", %{conn: conn} do
      user = user_fixture(confirmed: true)
      scope = Scope.for_user(user)
      resume = resume_fixture(scope, %{is_public: true})
      work_experience = work_experience_fixture(scope, resume, %{company_name: "Deleted Company"})

      {:ok, view, _html} = live(conn, ~p"/resumes/#{resume.id}")

      # Verify work experience is initially present
      assert render(view) =~ "Deleted Company"

      # Simulate a work experience deletion broadcast
      send(view.pid, {:deleted, work_experience})

      # Verify the work experience is removed from the view
      refute render(view) =~ "Deleted Company"
    end
  end
end
