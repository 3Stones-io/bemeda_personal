defmodule BemedaPersonalWeb.JobApplicationLive.ShowTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import BemedaPersonal.ResumesFixtures
  import Phoenix.LiveViewTest

  describe "/jobs/:job_id/job_applications/:id" do
    setup %{conn: conn} do
      user = user_fixture()
      company = company_fixture(user_fixture(%{email: "company@example.com"}))

      job =
        job_posting_fixture(company, %{
          title: "Senior Developer",
          description: "Build amazing applications",
          location: "Remote",
          employment_type: "Full-time"
        })

      job_application =
        job_application_fixture(user, job, %{
          cover_letter:
            "I am excited to apply for this position and believe my skills are a perfect match."
        })

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

    test "requires authentication for access", %{
      job_application: job_application
    } do
      public_conn = build_conn()

      response =
        get(
          public_conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert redirected_to(response) == ~p"/users/log_in"
    end

    test "renders job application details page", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert html =~ job_application.job_posting.title
      assert html =~ job_application.job_posting.company.name
      assert html =~ "Cover Letter"
      assert html =~ job_application.cover_letter
    end

    test "displays submission date", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      submission_date = Calendar.strftime(job_application.inserted_at, "%B %d, %Y")
      assert html =~ "Submitted on #{submission_date}"
    end

    test "shows resume warning when user has no resume", %{
      conn: conn
    } do
      user_without_resume = user_fixture(%{email: "no_resume@example.com"})
      authenticated_conn = log_in_user(conn, user_without_resume)

      company = company_fixture(user_fixture(%{email: "another_company@example.com"}))
      job = job_posting_fixture(company)
      job_application = job_application_fixture(user_without_resume, job)

      {:ok, _view, html} =
        live(
          authenticated_conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert html =~ "Create your resume"
    end

    test "does not show resume warning when user has a resume", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      refute html =~ "You haven&#39;t created a resume yet"
    end

    test "provides link to edit resume", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert view
             |> element("a", "Edit Your Resume")
             |> has_element?()
    end

    test "provides link to edit application", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert view
             |> element("a", "Edit application")
             |> has_element?()

      {:ok, _view, html} =
        view
        |> element("a", "Edit application")
        |> render_click()
        |> follow_redirect(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/edit"
        )

      assert html =~ "Edit application for"
    end

    test "provides link to job posting details", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      {:ok, _view, html} =
        view
        |> element("a", job_application.job_posting.title)
        |> render_click()
        |> follow_redirect(conn, ~p"/jobs/#{job_application.job_posting_id}")

      assert html =~ job_application.job_posting.title
      assert html =~ job_application.job_posting.description
    end

    test "displays video player when application has video", %{
      conn: conn,
      user: user,
      job: job
    } do
      job_application_with_video =
        job_application_fixture(
          user,
          job,
          %{
            cover_letter: "Application with video",
            mux_data: %{
              asset_id: "asset_123",
              playback_id: "test-playback-id",
              file_name: "test_video.mp4"
            }
          }
        )

      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application_with_video.job_posting_id}/job_applications/#{job_application_with_video.id}"
        )

      assert html =~ ~s(<mux-player playback-id="test-playback-id")
    end

    test "does not display video player when application has no video", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      refute html =~ "<mux-player"
    end
  end

  describe "/chat/:job_application_id" do
    setup %{conn: conn} do
      user = user_fixture()
      company = company_fixture(user_fixture(%{email: "company@example.com"}))

      job =
        job_posting_fixture(company, %{
          title: "Senior Developer",
          description: "Build amazing applications",
          location: "Remote",
          employment_type: "Full-time"
        })

      job_application =
        job_application_fixture(user, job, %{
          cover_letter:
            "I am excited to apply for this position and believe my skills are a perfect match."
        })

      conn = log_in_user(conn, user)

      %{
        conn: conn,
        user: user,
        job: job,
        job_application: job_application
      }
    end

    test "shows the cover letter in chat messages when viewing chat", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, _view, html} =
        live(conn, ~p"/chat/#{job_application.id}")

      assert html =~ job_application.cover_letter

      messages = BemedaPersonal.Jobs.list_messages(job_application)
      assert length(messages) == 1
      assert hd(messages).content == job_application.cover_letter
    end

    test "shows both video and cover letter when application has video", %{
      conn: conn,
      user: user,
      job: job
    } do
      job_application =
        job_application_fixture(
          user,
          job,
          %{
            cover_letter: "Application with video",
            mux_data: %{
              asset_id: "asset_123",
              playback_id: "test-playback-id",
              file_name: "test_video.mp4",
              type: "video/mp4"
            }
          }
        )

      {:ok, _view, html} =
        live(conn, ~p"/chat/#{job_application.id}")

      assert html =~ "Application with video"
      assert html =~ ~s(mux-player playback-id="test-playback-id")

      messages = BemedaPersonal.Jobs.list_messages(job_application)
      assert length(messages) == 2

      video_message = Enum.find(messages, fn m -> m.mux_data != nil end)
      text_message = Enum.find(messages, fn m -> m.content != nil end)

      assert video_message.mux_data.playback_id == "test-playback-id"
      assert text_message.content == "Application with video"
    end

    test "allows user to send new messages", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(conn, ~p"/chat/#{job_application.id}")

      message_content = "This is a new test message"

      view
      |> form("#chat-form", %{message: %{content: message_content}})
      |> render_submit()

      rendered_html = render(view)
      assert rendered_html =~ message_content

      messages = BemedaPersonal.Jobs.list_messages(job_application)
      assert length(messages) == 2

      new_message = Enum.find(messages, fn m -> m.content == message_content end)
      assert new_message.content == message_content
    end
  end
end
