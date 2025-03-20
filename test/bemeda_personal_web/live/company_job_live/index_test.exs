defmodule BemedaPersonalWeb.CompanyJobLive.IndexTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures

  alias BemedaPersonal.Jobs

  describe "/companies/:company_id" do
    setup %{conn: conn} do
      user = user_fixture(%{confirmed: true})
      company = company_fixture(user)
      job1 = job_posting_fixture(company, %{title: "Software Engineer"})
      job2 = job_posting_fixture(company, %{title: "Product Manager"})
      unauthorized_user = user_fixture(%{confirmed: true})

      %{
        conn: conn,
        user: user,
        unauthorized_user: unauthorized_user,
        company: company,
        job1: job1,
        job2: job2
      }
    end

    test "authorized user can see jobs listing", %{conn: conn, user: user, company: company, job1: job1, job2: job2} do
      {:ok, lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/jobs")

      assert html =~ "Jobs for #{company.name}"
      assert html =~ "Manage your job postings"
      assert html =~ "Post New Job"

      assert has_element?(lv, "#job_postings-#{job1.id}")
      assert has_element?(lv, "#job_postings-#{job2.id}")
      assert html =~ job1.title
      assert html =~ job2.title
    end

    test "unauthorized user is redirected", %{conn: conn, unauthorized_user: unauthorized_user, company: company} do
      {:error, redirect} =
        conn
        |> log_in_user(unauthorized_user)
        |> live(~p"/companies/#{company.id}/jobs")

      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/companies"
    end

    test "unauthenticated user is redirected to login", %{conn: conn, company: company} do
      {:error, redirect} = live(conn, ~p"/companies/#{company.id}/jobs")

      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/users/log_in"
    end

    test "renders new job form", %{conn: conn, user: user, company: company} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/jobs")

      lv
      |> element("a", "Post New Job")
      |> render_click()

      assert_patch(lv, ~p"/companies/#{company.id}/jobs/new")

      html = render(lv)
      assert html =~ "Job Title"
      assert html =~ "Job Description"
      assert html =~ "Employment Type"
    end

    test "can create a new job", %{conn: conn, user: user, company: company} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/jobs")

      lv
      |> element("a", "Post New Job")
      |> render_click()

      result =
        lv
        |> form("#job-posting-form", %{
          "job_posting" => %{
            "title" => "Test Engineer",
            "description" => "This is a test job",
            "employment_type" => "Full-time",
            "location" => "Remote",
            "experience_level" => "Mid Level",
            "remote_allowed" => true,
            "salary_min" => 50000,
            "salary_max" => 80000,
            "currency" => "USD"
          }
        })
        |> render_submit()

      assert result =~ "Job posted successfully"

      assert [job] = Jobs.list_job_postings(%{title: "Test Engineer"})
      assert job.employment_type == "Full-time"
    end

    test "form renders errors with invalid data", %{conn: conn, user: user, company: company} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/jobs")

      lv
      |> element("a", "Post New Job")
      |> render_click()

      result =
        lv
        |> form("#job-posting-form", %{
          "job_posting" => %{
            "title" => "",
            "description" => "",
            "salary_min" => 80000,
            "salary_max" => 50000
          }
        })
        |> render_change()

      assert result =~ "can&#39;t be blank"
      assert result =~ "must be less than or equal to"
    end

    test "can edit an existing job", %{conn: conn, user: user, company: company, job1: job1} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/jobs")

      lv
      |> element("a[href='/companies/#{company.id}/jobs/#{job1.id}/edit']")
      |> render_click()

      assert_patch(lv, ~p"/companies/#{company.id}/jobs/#{job1.id}/edit")

      result =
        lv
        |> form("#job-posting-form", %{
          "job_posting" => %{
            "title" => "Updated Job Title",
          }
        })
        |> render_submit()

      assert result =~ "Job updated successfully"

      updated_job = Jobs.get_job_posting!(job1.id)
      assert updated_job.title == "Updated Job Title"
    end

    test "job details links exist in the page", %{conn: conn, user: user, company: company, job1: job1} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/jobs")

      assert html =~ ~s|href="/jobs/#{job1.id}"|
    end

    test "back to dashboard link exists in the page", %{conn: conn, user: user, company: company} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/jobs")

      assert html =~ "Back to Dashboard"
      assert html =~ ~s|href="/companies"|
    end

    test "has filter UI elements", %{conn: conn, user: user, company: company} do
      job_posting_fixture(company, %{title: "Frontend Developer", employment_type: "Full-time"})
      job_posting_fixture(company, %{title: "Backend Developer", employment_type: "Contract"})

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/jobs")

      assert html =~ "Filter"

      assert html =~ "filters_title"
      assert html =~ "filters_employment_type"
      assert html =~ "filters_experience_level"

      assert html =~ "Frontend Developer"
      assert html =~ "Backend Developer"
    end
  end
end
