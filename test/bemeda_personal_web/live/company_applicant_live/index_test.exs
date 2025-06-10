defmodule BemedaPersonalWeb.CompanyApplicantLive.IndexTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures
  import BemedaPersonal.ResumesFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.JobApplications
  alias BemedaPersonalWeb.I18n

  setup %{conn: conn} do
    company_user = employer_user_fixture(%{email: "company@example.com"})
    company = company_fixture(company_user)
    job = job_posting_fixture(company)

    applicant_user =
      user_fixture(%{first_name: "John", last_name: "Doe", email: "applicant@example.com"})

    job_application = job_application_fixture(applicant_user, job)
    resume = resume_fixture(applicant_user)

    second_applicant =
      user_fixture(%{first_name: "Jane", last_name: "Smith", email: "jane@example.com"})

    today = Date.utc_today()
    yesterday = Date.add(today, -1)

    job2 = job_posting_fixture(company, %{title: "Second Job"})

    application2 =
      job_application_fixture(
        second_applicant,
        job2,
        %{inserted_at: DateTime.new!(yesterday, ~T[10:00:00])}
      )

    %{
      conn: conn,
      company: company,
      company_user: company_user,
      job: job,
      job2: job2,
      applicant: applicant_user,
      second_applicant: second_applicant,
      job_application: job_application,
      application2: application2,
      resume: resume,
      today: today,
      yesterday: yesterday
    }
  end

  describe "/company/:company_id/applicants" do
    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/company/applicants")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "redirects if user is not admin of the company", %{conn: conn} do
      other_user = employer_user_fixture(%{email: "other@example.com"})

      assert {:error, {:redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(other_user)
               |> live(~p"/company/applicants")

      assert path == ~p"/company/new"
      assert flash["error"] == "You need to create a company first."
    end

    test "renders all company applicants page", %{
      conn: conn,
      company_user: user,
      company: company,
      job_application: application
    } do
      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/applicants")

      assert html =~ "Applicants"
      assert html =~ company.name
      assert html =~ "#{application.user.first_name} #{application.user.last_name}"
      assert html =~ application.job_posting.title
    end

    test "allows navigation to applicant details", %{
      conn: conn,
      company_user: user,
      job_application: application
    } do
      conn = log_in_user(conn, user)

      assert {:ok, view, html} = live(conn, ~p"/company/applicants")
      assert html =~ "#{application.user.first_name} #{application.user.last_name}"

      assert {:error, {:live_redirect, %{to: path}}} =
               view
               |> element("#applicant-#{application.id}")
               |> render_click()

      assert path == ~p"/company/applicant/#{application.id}"
    end

    test "filters applicants by name through form submission", %{
      conn: conn,
      company_user: user,
      applicant: applicant,
      second_applicant: second_applicant
    } do
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/company/applicants")

      view
      |> form("#job_application_filter_form", %{
        job_application_filter: %{applicant_name: applicant.first_name}
      })
      |> render_submit()

      filtered_html = render(view)

      assert filtered_html =~ applicant.first_name
      refute filtered_html =~ second_applicant.first_name
    end

    test "filters applicants by tag through form submission", %{
      conn: conn,
      company_user: user,
      job: job
    } do
      conn = log_in_user(conn, user)

      application1 = job_application_fixture(user, job)
      application2 = job_application_fixture(user, job)
      application3 = job_application_fixture(user, job)

      JobApplications.update_job_application_tags(application1, "urgent,qualified")
      JobApplications.update_job_application_tags(application2, "urgent")
      JobApplications.update_job_application_tags(application3, "another")

      {:ok, view, _html} = live(conn, ~p"/company/applicants")

      view
      |> element("#job_application_filter_form")
      |> render_submit(%{
        "job_application_filter" => %{
          "tags" => "urgent"
        }
      })

      filtered_html = render(view)

      assert filtered_html =~ application1.user.first_name
      assert filtered_html =~ application2.user.first_name
      refute filtered_html =~ application3.id

      view
      |> element("#job_application_filter_form")
      |> render_submit(%{
        "job_application_filter" => %{
          "tags" => "another"
        }
      })

      filtered_html2 = render(view)

      refute filtered_html2 =~ application1.id
      refute filtered_html2 =~ application2.id
      assert filtered_html2 =~ application3.user.first_name
    end

    test "filters applicants by date range through form submission", %{
      conn: conn,
      company_user: user,
      applicant: applicant,
      second_applicant: second_applicant
    } do
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/company/applicants")

      view
      |> form("#job_application_filter_form", %{
        job_application_filter: %{
          applicant_name: applicant.first_name
        }
      })
      |> render_submit()

      first_filter_html = render(view)

      assert first_filter_html =~ applicant.first_name
      refute first_filter_html =~ second_applicant.first_name

      view
      |> form("#job_application_filter_form", %{
        job_application_filter: %{
          applicant_name: second_applicant.first_name
        }
      })
      |> render_submit()

      second_filter_html = render(view)

      refute second_filter_html =~ applicant.first_name
      assert second_filter_html =~ second_applicant.first_name
    end

    test "clear filters button works", %{
      conn: conn,
      company_user: user,
      applicant: applicant,
      second_applicant: second_applicant
    } do
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/company/applicants")

      view
      |> form("#job_application_filter_form", %{
        job_application_filter: %{applicant_name: applicant.first_name}
      })
      |> render_submit()

      filtered_html = render(view)
      assert filtered_html =~ applicant.first_name
      refute filtered_html =~ second_applicant.first_name

      view
      |> element("button", "Clear All")
      |> render_click()

      assert_patch(view, ~p"/company/applicants")

      clear_html = render(view)
      assert clear_html =~ applicant.first_name
      assert clear_html =~ second_applicant.first_name
    end

    test "handles URL query parameters correctly", %{
      conn: conn,
      company_user: user,
      company: company,
      applicant: applicant
    } do
      second_applicant = user_fixture(%{first_name: "Second", last_name: "Applicant"})
      job_application_fixture(second_applicant, job_posting_fixture(company))

      conn = log_in_user(conn, user)

      {:ok, view, html} =
        live(conn, ~p"/company/applicants?applicant_name=#{applicant.first_name}")

      assert html =~ "Filter Applications"
      assert html =~ "#{applicant.first_name} #{applicant.last_name}"
      refute html =~ "Second Applicant"

      input_html =
        view
        |> element("input[name='job_application_filter[applicant_name]']")
        |> render()

      assert input_html =~ "value=\"#{applicant.first_name}\""

      today = Date.utc_today()
      tomorrow = Date.add(today, 1)

      {:ok, date_view, _html} =
        live(
          conn,
          ~p"/company/applicants?date_from=#{Date.to_string(today)}&date_to=#{Date.to_string(tomorrow)}"
        )

      date_from_html =
        date_view
        |> element("input[name='job_application_filter[date_from]']")
        |> render()

      date_to_html =
        date_view
        |> element("input[name='job_application_filter[date_to]']")
        |> render()

      assert date_from_html =~ "value=\"#{Date.to_string(today)}\""
      assert date_to_html =~ "value=\"#{Date.to_string(tomorrow)}\""

      {:ok, unfiltered_view, unfiltered_html} = live(conn, ~p"/company/applicants")

      assert unfiltered_html =~ "#{applicant.first_name} #{applicant.last_name}"
      assert unfiltered_html =~ "Second Applicant"

      empty_input_html =
        unfiltered_view
        |> element("input[name='job_application_filter[applicant_name]']")
        |> render()

      refute empty_input_html =~ "value="
    end

    test "shows applicant's status", %{
      company_user: user,
      conn: conn,
      job_application: application
    } do
      conn = log_in_user(conn, user)

      {:ok, _view, html} = live(conn, ~p"/company/applicants")

      assert html =~ I18n.translate_status(application.state)
      assert html =~ "Status - update in chat interface"
    end

    test "updates applicants list when someone applies for the job", %{
      conn: conn,
      company_user: user,
      job: job
    } do
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/company/applicants")

      new_applicant =
        user_fixture(%{first_name: "New", last_name: "Applicant", email: "new@example.com"})

      {:ok, _new_application} =
        JobApplications.create_job_application(new_applicant, job, %{
          cover_letter: "I am very interested in this position"
        })

      Process.sleep(50)

      updated_html = render(view)

      assert updated_html =~ "New Applicant"
      assert updated_html =~ "new@example.com"
    end
  end

  describe "/company/:company_id/applicants/:job_id" do
    test "renders applicants for a specific job posting", %{
      conn: conn,
      company_user: user,
      company: company,
      job: job,
      job_application: application
    } do
      job_2 = job_posting_fixture(company, %{title: "Second Job"})
      job_application_2 = job_application_fixture(user, job_2)

      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/applicants/#{job.id}")

      assert html =~ "Applicants"
      assert html =~ job.title
      assert html =~ "#{application.user.first_name} #{application.user.last_name}"
      refute html =~ "#{job_application_2.user.first_name} #{job_application_2.user.last_name}"
    end

    test "filters job-specific applicants by name through form", %{
      conn: conn,
      company_user: user,
      job: job,
      applicant: applicant
    } do
      second_applicant = user_fixture(%{first_name: "Second", last_name: "Applicant"})
      job_application_fixture(second_applicant, job)

      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/company/applicants/#{job.id}")

      view
      |> form("#job_application_filter_form", %{
        job_application_filter: %{applicant_name: applicant.first_name}
      })
      |> render_submit()

      filtered_html = render(view)

      assert filtered_html =~ applicant.first_name
      refute filtered_html =~ "Second Applicant"
    end

    test "handles URL query parameters for job-specific applicants", %{
      conn: conn,
      company_user: user,
      job: job,
      applicant: applicant
    } do
      conn = log_in_user(conn, user)

      today = Date.utc_today()
      tomorrow = Date.add(today, 1)

      {:ok, view, html} =
        live(
          conn,
          ~p"/company/applicants/#{job.id}?applicant_name=#{applicant.first_name}&date_from=#{Date.to_string(today)}&date_to=#{Date.to_string(tomorrow)}"
        )

      assert html =~ job.title
      assert html =~ "Filter Applications"

      applicant_name_html =
        view
        |> element("input[name='job_application_filter[applicant_name]']")
        |> render()

      assert applicant_name_html =~ "value=\"#{applicant.first_name}\""

      {:ok, unfiltered_view, unfiltered_html} =
        live(conn, ~p"/company/applicants/#{job.id}")

      assert unfiltered_html =~ job.title

      empty_input_html =
        unfiltered_view
        |> element("input[name='job_application_filter[applicant_name]']")
        |> render()

      refute empty_input_html =~ "value="
    end
  end
end
