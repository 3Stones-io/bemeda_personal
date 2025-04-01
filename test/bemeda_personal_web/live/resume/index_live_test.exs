defmodule BemedaPersonalWeb.Resume.IndexLiveTest do
  use BemedaPersonalWeb.ConnCase, async: true

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
      assert html =~ resume.location

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
          location: nil,
          contact_email: nil,
          phone_number: nil,
          website_url: nil
        })

      {:ok, _public_live, html} = live(conn, ~p"/resumes/#{resume.id}")

      assert html =~ "Professional"
      assert html =~ "No summary provided"
      assert html =~ "Location not specified"
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
end
