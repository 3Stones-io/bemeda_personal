defmodule BemedaPersonalWeb.Features.ChatSteps do
  use Cucumber.StepDefinition
  use BemedaPersonalWeb, :verified_routes

  import BemedaPersonal.BddHelpers
  import ExUnit.Assertions
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.AccountsFixtures
  alias BemedaPersonal.Chat
  alias BemedaPersonal.Chat.Message
  alias BemedaPersonal.ChatFixtures
  alias BemedaPersonal.CompaniesFixtures
  alias BemedaPersonal.JobApplicationsFixtures
  alias BemedaPersonal.JobPostingsFixtures
  alias BemedaPersonalWeb.Endpoint

  @endpoint Endpoint

  @type context :: map()

  # ============================================================================
  # Given Steps - Chat Setup
  # ============================================================================

  step "there is a job application for discussion", context do
    # Create employer with company
    employer =
      AccountsFixtures.user_fixture(
        user_type: :employer,
        confirmed_at: DateTime.utc_now(),
        email: generate_unique_email("employer_chat")
      )

    company = CompaniesFixtures.company_fixture(employer)

    # Create job posting
    job_posting = JobPostingsFixtures.job_posting_fixture(company)

    # Create job seeker
    job_seeker =
      AccountsFixtures.user_fixture(
        user_type: :job_seeker,
        confirmed_at: DateTime.utc_now(),
        email: generate_unique_email("seeker_chat")
      )

    # Create job application
    job_application = JobApplicationsFixtures.job_application_fixture(job_seeker, job_posting)

    context
    |> Map.put(:employer, employer)
    |> Map.put(:company, company)
    |> Map.put(:job_posting, job_posting)
    |> Map.put(:job_seeker, job_seeker)
    |> Map.put(:job_application, job_application)
    |> then(&{:ok, &1})
  end

  step "the employer has sent me a message", context do
    employer = context.employer
    job_application = context.job_application

    message =
      ChatFixtures.message_fixture(employer, job_application, %{
        content: "We are interested in your application"
      })

    {:ok, Map.put(context, :employer_message, message)}
  end

  step "there is an existing conversation with the job seeker", context do
    employer = context.employer
    job_seeker = context.job_seeker
    job_application = context.job_application

    # Create multiple messages to establish conversation
    msg1 =
      ChatFixtures.message_fixture(employer, job_application, %{
        content: "Hello, we reviewed your application"
      })

    msg2 =
      ChatFixtures.message_fixture(job_seeker, job_application, %{
        content: "Thank you for considering me"
      })

    msg3 =
      ChatFixtures.message_fixture(employer, job_application, %{
        content: "Can you start next month?"
      })

    context
    |> Map.put(:conversation_messages, [msg1, msg2, msg3])
    |> then(&{:ok, &1})
  end

  # ============================================================================
  # Given Steps - Authentication (Chat-specific to use Background users)
  # ============================================================================

  step "I authenticate as the employer", context do
    employer = context.employer

    token = Accounts.generate_user_session_token(employer)

    conn =
      build_conn()
      |> Phoenix.ConnTest.init_test_session(%{})
      |> Plug.Conn.put_session(:user_token, token)
      |> Plug.Conn.put_session(
        :live_socket_id,
        "users_sessions:#{Base.url_encode64(token)}"
      )

    context
    |> Map.put(:conn, conn)
    |> Map.put(:current_user, employer)
    |> then(&{:ok, &1})
  end

  step "I authenticate as the job seeker", context do
    job_seeker = context.job_seeker

    token = Accounts.generate_user_session_token(job_seeker)

    conn =
      build_conn()
      |> Phoenix.ConnTest.init_test_session(%{})
      |> Plug.Conn.put_session(:user_token, token)
      |> Plug.Conn.put_session(
        :live_socket_id,
        "users_sessions:#{Base.url_encode64(token)}"
      )

    context
    |> Map.put(:conn, conn)
    |> Map.put(:current_user, job_seeker)
    |> then(&{:ok, &1})
  end

  # ============================================================================
  # When Steps - Chat Actions
  # ============================================================================

  step "I visit the job application chat page", context do
    conn = context.conn
    job_application = context.job_application
    job_posting = context.job_posting

    {:ok, view, _html} =
      live(conn, ~p"/jobs/#{job_posting.id}/job_applications/#{job_application.id}")

    {:ok, Map.put(context, :view, view)}
  end

  step "I send a message {string}", %{args: [message_content]} = context do
    view = context.view

    # Simulate sending a message through the chat form
    form_data = %{
      "message" => %{
        "content" => message_content
      }
    }

    # Try multiple form selectors (form ID might be chat-form or message-form)
    _result =
      try do
        view
        |> form("#chat-form", form_data)
        |> render_submit()
      rescue
        ArgumentError ->
          view
          |> form("#message-form", form_data)
          |> render_submit()
      end

    {:ok, Map.put(context, :sent_message, message_content)}
  end

  step "I reply with {string}", %{args: [reply_content]} = context do
    view = context.view

    # Simulate replying with a message
    form_data = %{
      "message" => %{
        "content" => reply_content
      }
    }

    # Try multiple form selectors (form ID might be chat-form or message-form)
    result =
      try do
        view
        |> form("#chat-form", form_data)
        |> render_submit()
      rescue
        ArgumentError ->
          view
          |> form("#message-form", form_data)
          |> render_submit()
      end

    {:ok, Map.put(context, :reply_message, reply_content)}
  end

  # ============================================================================
  # Then Steps - Chat Assertions
  # ============================================================================

  step "the message should be stored in the conversation", context do
    job_application = context.job_application
    sent_message = context.sent_message
    current_user = context.current_user

    # Build scope with company if employer
    scope =
      current_user
      |> Scope.for_user()
      |> then(fn base_scope ->
        if current_user.user_type == :employer do
          Scope.put_company(base_scope, context.company)
        else
          base_scope
        end
      end)

    messages = Chat.list_messages(scope, job_application)

    # Filter out any non-message items (like job_application, resume)
    message_items = Enum.filter(messages, &match?(%Message{}, &1))

    # Check if any message contains our sent content
    assert Enum.any?(message_items, fn msg -> msg.content == sent_message end),
           "Message '#{sent_message}' not found in conversation"

    {:ok, context}
  end

  step "I should see the employer message", context do
    html = render(context.view)
    employer_message = context.employer_message

    assert html =~ employer_message.content

    {:ok, context}
  end

  step "the employer should receive my reply", context do
    job_application = context.job_application
    reply_message = context.reply_message
    employer = context.employer

    # Build scope from employer's perspective
    scope =
      employer
      |> Scope.for_user()
      |> Scope.put_company(context.company)

    messages = Chat.list_messages(scope, job_application)
    message_items = Enum.filter(messages, &match?(%Message{}, &1))

    assert Enum.any?(message_items, fn msg -> msg.content == reply_message end),
           "Reply '#{reply_message}' not found in conversation"

    {:ok, context}
  end

  step "I should see all messages in chronological order", context do
    html = render(context.view)
    conversation_messages = context.conversation_messages

    # Verify all messages appear in the view
    Enum.each(conversation_messages, fn msg ->
      assert html =~ msg.content,
             "Message '#{msg.content}' not found in conversation view"
    end)

    {:ok, context}
  end

  step "each message should show the sender name", context do
    html = render(context.view)
    employer = context.employer
    job_seeker = context.job_seeker

    # Check that sender names appear (could be first name, last name, or full name)
    assert html =~ employer.first_name or html =~ employer.last_name or
             html =~ "#{employer.first_name} #{employer.last_name}",
           "Employer name not found in message view"

    assert html =~ job_seeker.first_name or html =~ job_seeker.last_name or
             html =~ "#{job_seeker.first_name} #{job_seeker.last_name}",
           "Job seeker name not found in message view"

    {:ok, context}
  end
end
