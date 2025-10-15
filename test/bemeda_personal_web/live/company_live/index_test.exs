defmodule BemedaPersonalWeb.CompanyLive.IndexTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures
  import BemedaPersonal.RatingsFixtures
  import Ecto.Query
  import Phoenix.LiveViewTest

  alias BemedaPersonal.CompanyTemplates
  alias BemedaPersonal.CompanyTemplates.CompanyTemplate
  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.Ratings
  alias BemedaPersonal.Repo
  alias BemedaPersonalWeb.Endpoint

  defp create_company(_context) do
    user = employer_user_fixture()
    company = company_fixture(user)
    %{company: company, user: user}
  end

  describe "Company Dashboard" do
    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/company")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "renders company dashboard when user has a company", %{conn: conn} do
      user = employer_user_fixture()
      company = company_fixture(user)

      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company")

      assert html =~ company.name
      assert html =~ company.industry
      assert html =~ "Company Dashboard"
      assert html =~ "Edit Company Profile"

      assert html =~ to_string(company.location)
      assert html =~ company.size

      assert html =~ company.website_url
      assert html =~ "hero-star"
    end

    test "shows job count correctly", %{conn: conn} do
      company_admin = employer_user_fixture(confirmed: true)
      company = company_fixture(company_admin)
      job_posting_fixture(company)
      job_posting_fixture(company)

      {:ok, _view, html} =
        conn
        |> log_in_user(company_admin)
        |> live(~p"/company")

      assert html =~ "Open Positions"
      assert html =~ "2"
    end

    test "users can edit their company", %{conn: conn} do
      company_admin = employer_user_fixture(confirmed: true)
      _company = company_fixture(company_admin)

      {:ok, view, _html} =
        conn
        |> log_in_user(company_admin)
        |> live(~p"/company")

      assert view
             |> element("a[href='/company/edit']")
             |> has_element?()
    end

    test "users can navigate to view all jobs", %{conn: conn} do
      user = employer_user_fixture()
      _company = company_fixture(user)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company")

      assert view
             |> element("a[href='/company/jobs']")
             |> has_element?()
    end

    test "redirects to company creation when user has no company", %{conn: conn} do
      user = employer_user_fixture()

      assert {:error, {:redirect, %{to: "/company/new"}}} =
               conn
               |> log_in_user(user)
               |> live(~p"/company")
    end

    test "user without company can access /company/new directly", %{conn: conn} do
      user = employer_user_fixture()

      {:ok, view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/new")

      assert html =~ "Create Company Profile"
      assert has_element?(view, "#company-form")
    end

    test "redirects to main dashboard if user already has company when accessing /company/new", %{
      conn: conn
    } do
      user = employer_user_fixture()
      _company = company_fixture(user)

      assert {:error, {:live_redirect, %{to: "/company", flash: flash}}} =
               conn
               |> log_in_user(user)
               |> live(~p"/company/new")

      assert flash["info"] =~ "You already have a company profile"
    end

    test "user without company can access /company/new page", %{conn: conn} do
      user = employer_user_fixture()

      {:ok, view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/new")

      assert html =~ "Create Company Profile"
      assert has_element?(view, "#company-form")
    end

    test "redirects from /company to /company/new when no company exists", %{conn: conn} do
      user = employer_user_fixture()

      assert {:error, {:redirect, %{to: "/company/new"}}} =
               conn
               |> log_in_user(user)
               |> live(~p"/company")
    end
  end

  describe "company ratings" do
    setup %{conn: conn} do
      company_admin = employer_user_fixture(confirmed: true)
      company = company_fixture(company_admin)
      user = user_fixture(confirmed: true)

      %{
        company: company,
        company_admin: company_admin,
        conn: log_in_user(conn, company_admin),
        user: user
      }
    end

    test "displays component with no ratings", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/company")

      assert html =~ "hero-star"
      assert html =~ "text-gray-300"
      refute html =~ "fill-current"
      assert html =~ "(0)"
      assert html =~ "No ratings yet"

      refute has_element?(view, "button", "Rate")
      refute has_element?(view, "button", "Update Rating")
    end

    test "displays component with one rating", %{
      company: company,
      conn: conn,
      user: user
    } do
      rating_fixture(%{
        ratee_id: company.id,
        ratee_type: "Company",
        rater_id: user.id,
        rater_type: "User",
        score: 4
      })

      {:ok, _view, html} = live(conn, ~p"/company")

      assert html =~ "4.0"
      assert html =~ "(1)"
      assert html =~ "fill-current"
      assert html =~ "text-gray-300"
    end

    test "displays partial rating correctly with decimal value", %{
      company: company,
      conn: conn
    } do
      user1 = user_fixture(confirmed: true)
      user2 = user_fixture(confirmed: true)

      rating_fixture(%{
        ratee_id: company.id,
        ratee_type: "Company",
        rater_id: user1.id,
        rater_type: "User",
        score: 3
      })

      rating_fixture(%{
        ratee_id: company.id,
        ratee_type: "Company",
        rater_id: user2.id,
        rater_type: "User",
        score: 4
      })

      {:ok, _view, html} = live(conn, ~p"/company")

      assert html =~ "3.5"
      assert html =~ "(2)"
      assert html =~ "fill-current"
    end

    test "rating display updates in real-time when ratings change", %{
      company: company,
      conn: conn
    } do
      user = user_fixture(confirmed: true)
      job_posting = job_posting_fixture(company)
      job_application_fixture(user, job_posting)

      {:ok, view, html} = live(conn, ~p"/company")

      assert html =~ "(0)"
      assert html =~ "No ratings yet"
      refute html =~ "fill-current"

      Ratings.rate_company(user, company, %{
        comment: "Excellent company!",
        score: 5
      })

      # Flaky test, sometimes the rating is not updated in time
      Process.sleep(100)

      updated_html = render(view)
      assert updated_html =~ "5.0"
      assert updated_html =~ "(1)"
      assert updated_html =~ "fill-current"
    end
  end

  describe "template management" do
    setup [:create_company]

    test "shows upload interface when no template exists", %{conn: conn, user: user} do
      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company")

      assert html =~ "Job Offer Template"
      assert html =~ "Upload a DOCX template with [[Variable_Name]] placeholders"
      refute html =~ "Replace Template"
      refute html =~ "bg-gray-50 rounded-lg"
    end

    test "handles template_status_updated broadcast", %{conn: conn, user: user, company: company} do
      {:ok, template} =
        CompanyTemplates.create_template(company, %{
          name: "processing_template.docx",
          status: :processing
        })

      {:ok, view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company")

      assert html =~ "processing_template.docx"
      assert html =~ "Processing"

      updated_template = %{
        template
        | status: :active,
          variables: ["FirstName", "LastName", "Position"]
      }

      Endpoint.broadcast(
        "company:#{company.id}:templates",
        "template_status_updated",
        updated_template
      )

      Process.sleep(10)

      updated_html = render(view)
      assert updated_html =~ "processing_template.docx"
      assert updated_html =~ "Active"
      refute updated_html =~ "Processing"
    end

    test "shows template management interface when template exists", %{
      company: company,
      conn: conn,
      user: user
    } do
      {:ok, _template} =
        CompanyTemplates.create_template(company, %{
          name: "test_template.docx",
          status: :active
        })

      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company")

      assert html =~ "test_template.docx"
      assert html =~ "Active"
      assert html =~ "hero-archive-box"
      assert html =~ "Replace Template"
      assert html =~ "Upload a new DOCX template to replace the current one"
      assert html =~ "bg-gray-50 rounded-lg"
    end

    test "successfully uploads a new template when none exists", %{
      company: company,
      conn: conn,
      user: user
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company")

      render_hook(view, "upload_file", %{
        "filename" => "new_template.docx",
        "type" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      })

      upload_response = render_hook(view, "upload_completed", %{})

      assert upload_response =~ "Template uploaded and processing started"
      assert upload_response =~ "new_template.docx"
      assert upload_response =~ "Processing"
      assert upload_response =~ "Replace Template"
      assert upload_response =~ "bg-gray-50 rounded-lg p-sm"

      query =
        from(t in CompanyTemplate,
          where: t.company_id == ^company.id,
          order_by: [desc: t.inserted_at],
          preload: [:media_asset]
        )

      templates = Repo.all(query)

      assert %CompanyTemplate{} =
               template =
               Enum.find(templates, &(&1.name == "new_template.docx"))

      assert template.status == :processing
    end

    test "successfully replaces an existing template", %{company: company, conn: conn, user: user} do
      {:ok, _existing_template} =
        CompanyTemplates.create_template(company, %{
          name: "old_template.docx",
          status: :active
        })

      {:ok, view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company")

      assert html =~ "old_template.docx"
      assert html =~ "Replace Template"

      render_hook(view, "upload_file", %{
        "filename" => "new_template.docx",
        "type" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      })

      upload_html = render_hook(view, "upload_completed", %{})

      assert upload_html =~ "Template uploaded and processing started"
      assert upload_html =~ "new_template.docx"
      refute upload_html =~ "old_template.docx"
      assert upload_html =~ "Processing"
      assert upload_html =~ "Replace Template"

      query =
        from(t in CompanyTemplate,
          where: t.company_id == ^company.id,
          order_by: [desc: t.inserted_at],
          preload: [:media_asset]
        )

      templates = Repo.all(query)

      assert %CompanyTemplate{} =
               new_template = Enum.find(templates, &(&1.name == "new_template.docx"))

      assert new_template.status == :processing

      assert %CompanyTemplate{} =
               old_template = Enum.find(templates, &(&1.name == "old_template.docx"))

      assert old_template.status == :active
    end

    test "successfully archives an existing template", %{company: company, conn: conn, user: user} do
      {:ok, _template} =
        CompanyTemplates.create_template(company, %{
          name: "template_to_archive.docx",
          status: :active
        })

      {:ok, view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company")

      assert html =~ "template_to_archive.docx"
      assert html =~ "Replace Template"

      archive_html =
        view
        |> element(".bg-gray-50 button[title='Archive template']")
        |> render_click()

      assert archive_html =~ "Template archived successfully"
      refute archive_html =~ "template_to_archive.docx"
      assert archive_html =~ "Job Offer Template"
      assert archive_html =~ "Upload a DOCX template with [[Variable_Name]] placeholders"
      refute archive_html =~ "Replace Template"
      refute archive_html =~ "bg-gray-50 rounded-lg p-4"

      refute CompanyTemplates.get_active_template(company.id)
    end

    test "rejects non-DOCX files during upload", %{conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company")

      html =
        render_hook(view, "upload_file", %{
          "filename" => "document.pdf",
          "type" => "application/pdf"
        })

      assert html =~ "Job Offer Template"
      assert html =~ "Upload a DOCX template with [[Variable_Name]] placeholders"
      refute html =~ "Replace Template"
    end

    test "rejects files with wrong extension during upload", %{
      conn: conn,
      user: user,
      company: _company
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company")

      html =
        render_hook(view, "upload_file", %{
          "filename" => "document.txt",
          "type" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        })

      assert html =~ "Job Offer Template"
      assert html =~ "Upload a DOCX template with [[Variable_Name]] placeholders"
      refute html =~ "Replace Template"
    end

    test "handles upload cancellation gracefully", %{conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company")

      render_hook(view, "upload_file", %{
        "filename" => "template.docx",
        "type" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      })

      html = render_hook(view, "delete_file", %{})

      assert html =~ "Upload a DOCX template with [[Variable_Name]] placeholders"
      refute html =~ "Replace Template"
    end

    test "handles template archiving when template is already archived", %{
      company: company,
      conn: conn,
      user: user
    } do
      {:ok, template} =
        CompanyTemplates.create_template(company, %{
          name: "template_to_archive.docx",
          status: :active
        })

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company")

      CompanyTemplates.update_template(template, %{status: :archived})

      html =
        view
        |> element(".bg-gray-50 button[title='Archive template']")
        |> render_click()

      assert html =~ "Template archived successfully"
      refute html =~ "Failed to archive template"
      refute html =~ "template_to_archive.docx"
      refute html =~ "Replace Template"
      refute html =~ "bg-gray-50 rounded-lg"
    end

    test "shows appropriate interface transitions during template lifecycle", %{
      conn: conn,
      user: user
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company")

      refute html =~ "Replace Template"
      refute html =~ "bg-gray-50 rounded-lg"
      assert html =~ "Upload a DOCX template with [[Variable_Name]] placeholders"

      render_hook(view, "upload_file", %{
        "filename" => "first_template.docx",
        "type" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      })

      upload_html = render_hook(view, "upload_completed", %{})

      assert upload_html =~ "first_template.docx"
      assert upload_html =~ "Processing"
      assert upload_html =~ "Replace Template"
      assert upload_html =~ "bg-gray-50 rounded-lg p-sm"

      render_hook(view, "upload_file", %{
        "filename" => "second_template.docx",
        "type" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      })

      upload_html_2 = render_hook(view, "upload_completed", %{})

      assert upload_html_2 =~ "second_template.docx"
      refute upload_html_2 =~ "first_template.docx"
      assert upload_html_2 =~ "Processing"
      assert upload_html_2 =~ "Replace Template"

      archive_html =
        view
        |> element(".bg-gray-50 button[title='Archive template']")
        |> render_click()

      assert archive_html =~ "Template archived successfully"
      refute archive_html =~ "second_template.docx"
      assert archive_html =~ "Upload a DOCX template with [[Variable_Name]] placeholders"
      refute archive_html =~ "Replace Template"
      refute archive_html =~ "bg-gray-50 rounded-lg p-4"
    end

    test "handles archive template action", %{conn: conn, user: user, company: company} do
      {:ok, _template} =
        CompanyTemplates.create_template(company, %{
          name: "template_to_archive.docx",
          status: :active
        })

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company")

      html = render_hook(view, "archive_template", %{})

      assert html =~ "Template archived successfully"
      refute html =~ "template_to_archive.docx"
    end

    test "handles archive template when no template exists", %{conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company")

      assert render_hook(view, "archive_template", %{}) =~ "Upload a DOCX template"
    end

    test "handles show variables modal", %{conn: conn, user: user, company: company} do
      {:ok, _template} =
        CompanyTemplates.create_template(company, %{
          name: "template_with_variables.docx",
          status: :active,
          variables: ["FirstName", "LastName", "Position"]
        })

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company")

      html = render_hook(view, "show_variables", %{})

      assert html =~ "template_with_variables.docx"
      assert html =~ "FirstName"
      assert html =~ "LastName"
      assert html =~ "Position"
    end

    test "handles close modal action", %{conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company")

      html = render_hook(view, "close_modal", %{})

      assert html =~ "Upload a DOCX template"
      refute html =~ "template_with_variables.docx"
    end
  end

  describe "My Schedule Tab" do
    test "displays schedule tab and calendar component", %{conn: conn} do
      user = employer_user_fixture()
      _company = company_fixture(user)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company")

      # Should show the schedule tab
      assert has_element?(view, "button", "My Schedule")

      # Click the schedule tab
      view
      |> element("button", "My Schedule")
      |> render_click()

      updated_html = render(view)

      # Calendar component should be rendered
      assert updated_html =~ "View and manage your upcoming interviews"
      assert updated_html =~ "calendar-container"

      # Should show current month
      current_month = Calendar.strftime(Date.utc_today(), "%B %Y")
      assert updated_html =~ current_month

      # Should have navigation buttons
      assert has_element?(view, "button[phx-click='prev_month']")
      assert has_element?(view, "button[phx-click='next_month']")
    end

    test "calendar navigation works correctly", %{conn: conn} do
      user = employer_user_fixture()
      _company = company_fixture(user)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company")

      # Click the schedule tab first
      view
      |> element("button", "My Schedule")
      |> render_click()

      # Get current month for comparison
      current_date = Date.utc_today()
      current_month = Calendar.strftime(current_date, "%B %Y")

      # Should show current month initially
      html = render(view)
      assert html =~ current_month

      # Click next month button
      view
      |> element("button[phx-click='next_month']")
      |> render_click()

      # Should show next month
      next_month =
        current_date
        |> Date.end_of_month()
        |> Date.add(1)
        |> Date.beginning_of_month()
        |> Calendar.strftime("%B %Y")

      updated_html = render(view)
      assert updated_html =~ next_month
    end
  end

  describe "Job Management" do
    test "allows creating a new job posting", %{conn: conn} do
      user = employer_user_fixture()
      _company = company_fixture(user)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/jobs/new")

      assert has_element?(view, "form[phx-submit='save']")
    end

    test "updates applicants list when someone applies for the job", %{conn: conn} do
      company_user = employer_user_fixture()
      company = company_fixture(company_user)
      job_posting = job_posting_fixture(company)

      job_applicant =
        user_fixture(%{first_name: "New", last_name: "Applicant", email: "new@example.com"})

      {:ok, view, _html} =
        conn
        |> log_in_user(company_user)
        |> live(~p"/company")

      # Switch to applicants tab BEFORE creating the application
      view
      |> element("button", "Applicants")
      |> render_click()

      {:ok, new_application} =
        JobApplications.create_job_application(job_applicant, job_posting, %{
          cover_letter: "I am very interested in this position"
        })

      # Wait longer for PubSub message to propagate
      Process.sleep(100)

      updated_html = render(view)

      # Debug: Check if the application was created
      assert new_application.user.first_name == "New"
      assert new_application.user.last_name == "Applicant"

      # Check if the applicant appears in the UI
      assert updated_html =~ "New Applicant"
      assert updated_html =~ "new@example.com"
    end
  end
end
