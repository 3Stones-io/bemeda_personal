defmodule BemedaPersonalWeb.Resume.IndexLiveTest do
  use BemedaPersonalWeb.ConnCase, async: false

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.ResumesFixtures
  import Phoenix.LiveViewTest

  describe "/resumes/:id" do
    test "displays resume with all sections", %{conn: conn} do
      user = user_fixture(confirmed: true)
      resume = resume_fixture(user, %{is_public: true})
      education = education_fixture(resume)
      work_experience = work_experience_fixture(resume)

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
      resume = resume_fixture(user, %{is_public: true})

      {:ok, _public_live, html} = live(conn, ~p"/resumes/#{resume.id}")

      assert html =~ "No education entries available."
      assert html =~ "No work experience entries available."
    end

    test "handles missing optional fields gracefully", %{conn: conn} do
      user = user_fixture(confirmed: true)

      resume =
        resume_fixture(user, %{
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
      resume = resume_fixture(user, %{is_public: false})

      {:ok, _public_live, html} = live(conn, ~p"/resumes/#{resume.id}")

      assert html =~ "404"
      assert html =~ "Resume Not Found"
      assert html =~ "doesn&#39;t exist or is not available"
    end
  end

  describe "PubSub broadcast handling" do
    test "handles resume_updated broadcast when resume is public", %{conn: conn} do
      user = user_fixture(confirmed: true)
      resume = resume_fixture(user, %{is_public: true})

      {:ok, view, _html} = live(conn, ~p"/resumes/#{resume.id}")

      # Simulate a resume update broadcast
      updated_resume = %{resume | headline: "Updated Headline"}
      payload = %{resume: updated_resume}

      send(view.pid, %Phoenix.Socket.Broadcast{
        event: "resume_updated",
        payload: payload
      })

      # Verify the resume was updated in the view
      assert render(view) =~ "Updated Headline"
    end

    test "handles resume_updated broadcast when resume becomes private", %{conn: conn} do
      user = user_fixture(confirmed: true)
      resume = resume_fixture(user, %{is_public: true})

      {:ok, view, _html} = live(conn, ~p"/resumes/#{resume.id}")

      # Simulate a resume update that makes it private
      private_resume = %{resume | is_public: false}
      payload = %{resume: private_resume}

      send(view.pid, %Phoenix.Socket.Broadcast{
        event: "resume_updated",
        payload: payload
      })

      # Verify the view now shows 404
      assert render(view) =~ "404"
      assert render(view) =~ "Resume Not Found"
    end

    test "handles education_updated broadcast", %{conn: conn} do
      user = user_fixture(confirmed: true)
      resume = resume_fixture(user, %{is_public: true})

      {:ok, view, _html} = live(conn, ~p"/resumes/#{resume.id}")

      # Simulate an education update broadcast
      education = education_fixture(resume, %{institution: "Test University"})
      payload = %{education: education}

      send(view.pid, %Phoenix.Socket.Broadcast{
        event: "education_updated",
        payload: payload
      })

      # Verify the education appears in the view
      assert render(view) =~ "Test University"
    end

    test "handles education_deleted broadcast", %{conn: conn} do
      user = user_fixture(confirmed: true)
      resume = resume_fixture(user, %{is_public: true})
      education = education_fixture(resume, %{institution: "Deleted University"})

      {:ok, view, _html} = live(conn, ~p"/resumes/#{resume.id}")

      # Verify education is initially present
      assert render(view) =~ "Deleted University"

      # Simulate an education deletion broadcast
      payload = %{education: education}

      send(view.pid, %Phoenix.Socket.Broadcast{
        event: "education_deleted",
        payload: payload
      })

      # Verify the education is removed from the view
      refute render(view) =~ "Deleted University"
    end

    test "handles work_experience_updated broadcast", %{conn: conn} do
      user = user_fixture(confirmed: true)
      resume = resume_fixture(user, %{is_public: true})

      {:ok, view, _html} = live(conn, ~p"/resumes/#{resume.id}")

      # Simulate a work experience update broadcast
      work_experience = work_experience_fixture(resume, %{company_name: "Test Company"})
      payload = %{work_experience: work_experience}

      send(view.pid, %Phoenix.Socket.Broadcast{
        event: "work_experience_updated",
        payload: payload
      })

      # Verify the work experience appears in the view
      assert render(view) =~ "Test Company"
    end

    test "handles work_experience_deleted broadcast", %{conn: conn} do
      user = user_fixture(confirmed: true)
      resume = resume_fixture(user, %{is_public: true})
      work_experience = work_experience_fixture(resume, %{company_name: "Deleted Company"})

      {:ok, view, _html} = live(conn, ~p"/resumes/#{resume.id}")

      # Verify work experience is initially present
      assert render(view) =~ "Deleted Company"

      # Simulate a work experience deletion broadcast
      payload = %{work_experience: work_experience}

      send(view.pid, %Phoenix.Socket.Broadcast{
        event: "work_experience_deleted",
        payload: payload
      })

      # Verify the work experience is removed from the view
      refute render(view) =~ "Deleted Company"
    end
  end
end
