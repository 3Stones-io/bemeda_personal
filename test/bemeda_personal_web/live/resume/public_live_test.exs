defmodule BemedaPersonalWeb.Resume.PublicLiveTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.ResumesFixtures

  # Setup for public resume tests
  defp create_public_resume(_params_unused) do
    user = user_fixture(confirmed: true)
    resume = resume_fixture(user, %{is_public: true})
    %{user: user, resume: resume}
  end

  # Setup for private resume tests
  defp create_private_resume(_params_unused) do
    user = user_fixture(confirmed: true)
    resume = resume_fixture(user, %{is_public: false})
    %{user: user, resume: resume}
  end

  # Setup for education tests
  defp create_education(%{resume: resume}) do
    education = education_fixture(resume)
    %{education: education}
  end

  # Setup for work experience tests
  defp create_work_experience(%{resume: resume}) do
    work_experience = work_experience_fixture(resume)
    %{work_experience: work_experience}
  end

  # Setup for resume with empty fields
  defp create_resume_with_empty_fields(_params_unused) do
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

    %{user: user, resume: resume}
  end

  describe "/resume/:id" do
    setup [:create_public_resume, :create_education, :create_work_experience]

    test "displays resume with all sections", %{
      conn: conn,
      resume: resume,
      education: education,
      work_experience: work_experience
    } do
      {:ok, _public_live, html} = live(conn, ~p"/resume/#{resume.id}")

      # Resume header information
      assert html =~ "Resume"
      assert html =~ resume.headline
      assert html =~ resume.summary
      assert html =~ resume.location

      # Education section
      assert html =~ "Education"
      assert html =~ education.institution
      assert html =~ education.degree
      assert html =~ education.field_of_study

      # Work experience section
      assert html =~ "Work Experience"
      assert html =~ work_experience.company_name
      assert html =~ work_experience.title
      assert html =~ work_experience.location

      # Contact information
      assert html =~ resume.contact_email
      assert html =~ resume.phone_number
      assert html =~ resume.website_url

      # No edit controls for public view
      refute html =~ "Edit"
      refute html =~ "Add"
      refute html =~ "Delete"
    end
  end

  describe "/resume/:id with empty sections" do
    setup [:create_public_resume]

    test "displays resume with empty education and work experience sections", %{
      conn: conn,
      resume: resume
    } do
      {:ok, _public_live, html} = live(conn, ~p"/resume/#{resume.id}")

      assert html =~ "No education entries available."
      assert html =~ "No work experience entries available."
    end
  end

  describe "/resume/:id with empty fields" do
    setup [:create_resume_with_empty_fields]

    test "handles missing optional fields gracefully", %{conn: conn, resume: resume} do
      {:ok, _public_live, html} = live(conn, ~p"/resume/#{resume.id}")

      assert html =~ "Professional"
      assert html =~ "No summary provided"
      assert html =~ "Location not specified"
      assert html =~ "Email not provided"
      assert html =~ "Phone not specified"
      assert html =~ "Website not specified"
    end
  end

  describe "/resume/:id with non-existent or private resume" do
    setup [:create_private_resume]

    test "shows 404 when resume does not exist", %{conn: conn} do
      {:ok, _public_live, html} = live(conn, ~p"/resume/#{Ecto.UUID.generate()}")

      assert html =~ "404"
      assert html =~ "Resume Not Found"
      assert html =~ "doesn&#39;t exist or is not available"
    end

    test "shows 404 when resume is not public", %{conn: conn, resume: resume} do
      {:ok, _public_live, html} = live(conn, ~p"/resume/#{resume.id}")

      assert html =~ "404"
      assert html =~ "Resume Not Found"
      assert html =~ "doesn&#39;t exist or is not available"
    end
  end
end
