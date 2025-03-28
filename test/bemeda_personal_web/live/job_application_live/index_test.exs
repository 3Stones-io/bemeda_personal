defmodule BemedaPersonalWeb.JobApplicationLive.IndexTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import BemedaPersonal.ResumesFixtures
  import Phoenix.LiveViewTest

  # Common setup to reduce code duplication
  defp create_test_data(conn) do
    user = user_fixture()
    company = company_fixture(user_fixture(%{email: "company@example.com"}))
    job = job_posting_fixture(company)
    job_application = job_application_fixture(user, job)
    resume = resume_fixture(user)

    conn = log_in_user(conn, user)

    %{
      conn: conn,
      company: company,
      user: user,
      job: job,
      job_application: job_application,
      resume: resume
    }
  end

  describe "/jobs/:job_id/job_applications" do
    setup %{conn: conn} do
      base_data = create_test_data(conn)

      # Add additional data specific to this test group
      job2 = job_posting_fixture(base_data.company, %{title: "Another Job"})
      job_application2 = job_application_fixture(base_data.user, job2)

      Map.merge(base_data, %{
        job2: job2,
        job_application2: job_application2
      })
    end

    test "requires authentication for access", %{
      job_application: job_application
    } do
      public_conn = build_conn()

      response = get(public_conn, ~p"/jobs/#{job_application.job_posting_id}/job_applications")
      assert redirected_to(response) == ~p"/users/log_in"
    end

    test "renders my job applications page", %{
      conn: conn,
      job_application: job_application,
      job_application2: job_application2
    } do
      {:ok, _view, html} =
        live(conn, ~p"/jobs/#{job_application.job_posting_id}/job_applications")

      assert html =~ "My Job Applications"
      assert html =~ job_application.job_posting.title
      assert html =~ job_application2.job_posting.title
    end

    test "allows viewing job application details", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(conn, ~p"/jobs/#{job_application.job_posting_id}/job_applications")

      {:ok, _view, html} =
        view
        |> element("div[phx-click]", job_application.job_posting.title)
        |> render_click()
        |> follow_redirect(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert html =~ job_application.job_posting.title
      assert html =~ job_application.cover_letter
    end

    test "provides link to edit application", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(conn, ~p"/jobs/#{job_application.job_posting_id}/job_applications")

      edit_link_selector = "a[href*='#{job_application.id}/edit']"

      assert view
             |> element(edit_link_selector)
             |> has_element?()

      {:ok, _view, html} =
        view
        |> element(edit_link_selector)
        |> render_click()
        |> follow_redirect(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/edit"
        )

      assert html =~ "Edit application for"
    end

    test "provides link to view job posting", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(conn, ~p"/jobs/#{job_application.job_posting_id}/job_applications")

      view_job_selector = "a[href='/jobs/#{job_application.job_posting_id}']"

      assert view
             |> element(view_job_selector)
             |> has_element?()

      {:ok, _view, html} =
        view
        |> element(view_job_selector)
        |> render_click()
        |> follow_redirect(conn, ~p"/jobs/#{job_application.job_posting_id}")

      assert html =~ job_application.job_posting.title
      assert html =~ job_application.job_posting.description
    end

    test "displays application date", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, _view, html} =
        live(conn, ~p"/jobs/#{job_application.job_posting_id}/job_applications")

      application_date = DateTime.to_date(job_application.inserted_at)
      formatted_date = BemedaPersonal.DateUtils.format_date(application_date)

      assert html =~ "Applied on #{formatted_date}"
    end
  end

  describe "/jobs/:job_id/job_applications/new" do
    setup %{conn: conn} do
      create_test_data(conn)
    end

    test "requires authentication for access", %{
      job: job
    } do
      public_conn = build_conn()

      response = get(public_conn, ~p"/jobs/#{job.id}/job_applications/new")
      assert redirected_to(response) == ~p"/users/log_in"
    end

    test "renders new application form", %{
      conn: conn,
      job: job
    } do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}/job_applications/new")

      assert html =~ "Apply to #{job.title}"
      assert html =~ "Cover Letter"
      assert html =~ "Submit Application"
    end

    test "validates required fields when submitting the form", %{
      conn: conn,
      job: job
    } do
      {:ok, view, _html} = live(conn, ~p"/jobs/#{job.id}/job_applications/new")

      html =
        view
        |> form("#job_application-form", %{
          "job_application" => %{
            "cover_letter" => ""
          }
        })
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "/jobs/:job_id/job_applications/:id/edit" do
    setup %{conn: conn} do
      create_test_data(conn)
    end

    test "requires authentication for access", %{
      job_application: job_application
    } do
      public_conn = build_conn()

      response =
        get(
          public_conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/edit"
        )

      assert redirected_to(response) == ~p"/users/log_in"
    end

    test "renders edit application form", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/edit"
        )

      assert html =~ "Edit application for #{job_application.job_posting.title}"
      assert html =~ "Cover Letter"
      assert html =~ job_application.cover_letter
      assert html =~ "Submit Application"
    end

    test "validation works when updating job application", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/edit"
        )

      html =
        view
        |> form("#job_application-form", %{
          "job_application" => %{
            "cover_letter" => ""
          }
        })
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "job application form submission" do
    setup do
      user = user_fixture()
      company = company_fixture(user_fixture(%{email: "company@example.com"}))
      job = job_posting_fixture(company)
      job_application = job_application_fixture(user, job)
      resume = resume_fixture(user)

      conn = log_in_user(build_conn(), user)

      %{
        conn: conn,
        company: company,
        user: user,
        job: job,
        job_application: job_application,
        resume: resume
      }
    end

    test "submits new job application successfully", %{
      conn: conn,
      job: job
    } do
      {:ok, view, _html} = live(conn, ~p"/jobs/#{job.id}/job_applications/new")

      assert view
             |> form("#job_application-form", %{
               "job_application" => %{
                 "cover_letter" =>
                   "I am very interested in this position. Please consider my application."
               }
             })
             |> render_submit()

      assert_redirect(view, ~p"/jobs/#{job.id}/job_applications")

      applications = BemedaPersonal.Jobs.list_job_applications(%{job_posting_id: job.id})
      assert length(applications) > 0

      created_application =
        Enum.find(applications, fn app ->
          app.cover_letter ==
            "I am very interested in this position. Please consider my application."
        end)

      assert created_application != nil
    end

    test "updates existing job application successfully", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/edit"
        )

      assert view
             |> form("#job_application-form", %{
               "job_application" => %{
                 "cover_letter" => "Updated cover letter with more details about my experience."
               }
             })
             |> render_submit()

      assert_redirect(view, ~p"/jobs/#{job_application.job_posting_id}/job_applications")

      updated_application = BemedaPersonal.Jobs.get_job_application!(job_application.id)

      assert updated_application.cover_letter ==
               "Updated cover letter with more details about my experience."
    end
  end
end
