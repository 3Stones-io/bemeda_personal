defmodule BemedaPersonal.Accounts.InterviewNotifier do
  @moduledoc """
  Handles email notifications for interview scheduling, reminders, and updates.
  """

  use Gettext, backend: BemedaPersonalWeb.Gettext

  alias BemedaPersonal.Accounts.EmailDelivery

  @type email :: Swoosh.Email.t()

  @spec deliver_interview_scheduled(BemedaPersonal.Scheduling.Interview.t()) :: {:ok, any()}
  def deliver_interview_scheduled(%BemedaPersonal.Scheduling.Interview{} = interview) do
    interview = preload_interview_associations(interview)

    job_seeker = interview.job_application.user
    employer = interview.created_by
    company = interview.job_application.job_posting.company

    # Email to job seeker
    EmailDelivery.put_locale(job_seeker)

    job_seeker_text_body = """
    #{dgettext("emails", "Hello")} #{job_seeker.first_name},

    #{dgettext("emails", "Good news! An interview has been scheduled for your application.")}

    #{dgettext("emails", "Position")}: #{interview.job_application.job_posting.title}
    #{dgettext("emails", "Company")}: #{company.name}
    #{dgettext("emails", "Date")}: #{format_interview_date(interview)}
    #{dgettext("emails", "Time")}: #{format_interview_time(interview)}
    #{dgettext("emails", "Duration")}: #{calculate_duration(interview)}
    #{dgettext("emails", "Meeting Link")}: #{interview.meeting_link}

    #{if interview.notes, do: dgettext("emails", "Notes") <> ": " <> interview.notes, else: ""}

    #{dgettext("emails", "Please make sure to join the meeting on time.")}

    #{dgettext("emails", "Best regards")},
    #{company.name}
    """

    job_seeker_html_body = String.replace(job_seeker_text_body, "\n", "<br>")

    deliver(
      job_seeker,
      dgettext("emails", "Interview Scheduled"),
      job_seeker_html_body,
      job_seeker_text_body
    )

    # Email to employer (confirmation)
    EmailDelivery.put_locale(employer)

    employer_text_body = """
    #{dgettext("emails", "Hello")} #{employer.first_name},

    #{dgettext("emails", "Your interview has been scheduled successfully.")}

    #{dgettext("emails", "Candidate")}: #{job_seeker.first_name} #{job_seeker.last_name}
    #{dgettext("emails", "Position")}: #{interview.job_application.job_posting.title}
    #{dgettext("emails", "Date")}: #{format_interview_date(interview)}
    #{dgettext("emails", "Time")}: #{format_interview_time(interview)}
    #{dgettext("emails", "Meeting Link")}: #{interview.meeting_link}

    #{dgettext("emails", "A reminder will be sent %{minutes} minutes before the interview.", minutes: interview.reminder_minutes_before)}

    #{dgettext("emails", "Best regards")},
    #{dgettext("emails", "BemedaPersonal Team")}
    """

    employer_html_body = String.replace(employer_text_body, "\n", "<br>")

    deliver(
      employer,
      dgettext("emails", "Interview Scheduled - Confirmation"),
      employer_html_body,
      employer_text_body
    )

    {:ok, :emails_sent}
  end

  @spec deliver_interview_reminder(BemedaPersonal.Scheduling.Interview.t()) :: {:ok, any()}
  def deliver_interview_reminder(%BemedaPersonal.Scheduling.Interview{} = interview) do
    interview = preload_interview_associations(interview)

    job_seeker = interview.job_application.user
    employer = interview.created_by
    company = interview.job_application.job_posting.company

    time_until = format_time_until(interview.scheduled_at)

    # Reminder to job seeker
    EmailDelivery.put_locale(job_seeker)

    job_seeker_text_body = """
    #{dgettext("emails", "Hello")} #{job_seeker.first_name},

    #{dgettext("emails", "This is a reminder that your interview is coming up in %{time}.", time: time_until)}

    #{dgettext("emails", "Position")}: #{interview.job_application.job_posting.title}
    #{dgettext("emails", "Company")}: #{company.name}
    #{dgettext("emails", "Time")}: #{format_interview_time(interview)}
    #{dgettext("emails", "Meeting Link")}: #{interview.meeting_link}

    #{dgettext("emails", "Please make sure you're ready to join the meeting.")}

    #{dgettext("emails", "Good luck!")},
    #{company.name}
    """

    job_seeker_html_body = String.replace(job_seeker_text_body, "\n", "<br>")

    deliver(
      job_seeker,
      dgettext("emails", "Interview Reminder"),
      job_seeker_html_body,
      job_seeker_text_body
    )

    # Reminder to employer
    EmailDelivery.put_locale(employer)

    employer_text_body = """
    #{dgettext("emails", "Hello")} #{employer.first_name},

    #{dgettext("emails", "Reminder: You have an interview scheduled in %{time}.", time: time_until)}

    #{dgettext("emails", "Candidate")}: #{job_seeker.first_name} #{job_seeker.last_name}
    #{dgettext("emails", "Position")}: #{interview.job_application.job_posting.title}
    #{dgettext("emails", "Meeting Link")}: #{interview.meeting_link}

    #{dgettext("emails", "Best regards")},
    #{dgettext("emails", "BemedaPersonal Team")}
    """

    employer_html_body = String.replace(employer_text_body, "\n", "<br>")

    deliver(
      employer,
      dgettext("emails", "Interview Reminder"),
      employer_html_body,
      employer_text_body
    )

    {:ok, :reminders_sent}
  end

  @spec deliver_interview_cancelled(BemedaPersonal.Scheduling.Interview.t()) :: {:ok, any()}
  def deliver_interview_cancelled(%BemedaPersonal.Scheduling.Interview{} = interview) do
    interview = preload_interview_associations(interview)

    job_seeker = interview.job_application.user
    employer = interview.created_by
    company = interview.job_application.job_posting.company

    # Notification to job seeker
    EmailDelivery.put_locale(job_seeker)

    job_seeker_text_body = """
    #{dgettext("emails", "Hello")} #{job_seeker.first_name},

    #{dgettext("emails", "We regret to inform you that your scheduled interview has been cancelled.")}

    #{dgettext("emails", "Position")}: #{interview.job_application.job_posting.title}
    #{dgettext("emails", "Company")}: #{company.name}
    #{dgettext("emails", "Originally scheduled for")}: #{format_interview_date(interview)} #{format_interview_time(interview)}

    #{if interview.cancellation_reason, do: dgettext("emails", "Reason") <> ": " <> interview.cancellation_reason, else: ""}

    #{dgettext("emails", "We apologize for any inconvenience. The employer may reach out to reschedule.")}

    #{dgettext("emails", "Best regards")},
    #{company.name}
    """

    job_seeker_html_body = String.replace(job_seeker_text_body, "\n", "<br>")

    deliver(
      job_seeker,
      dgettext("emails", "Interview Cancelled"),
      job_seeker_html_body,
      job_seeker_text_body
    )

    # Confirmation to employer
    EmailDelivery.put_locale(employer)

    employer_text_body = """
    #{dgettext("emails", "Hello")} #{employer.first_name},

    #{dgettext("emails", "The interview has been cancelled as requested.")}

    #{dgettext("emails", "Candidate")}: #{job_seeker.first_name} #{job_seeker.last_name}
    #{dgettext("emails", "Position")}: #{interview.job_application.job_posting.title}
    #{dgettext("emails", "Was scheduled for")}: #{format_interview_date(interview)} #{format_interview_time(interview)}

    #{dgettext("emails", "The candidate has been notified of the cancellation.")}

    #{dgettext("emails", "Best regards")},
    #{dgettext("emails", "BemedaPersonal Team")}
    """

    employer_html_body = String.replace(employer_text_body, "\n", "<br>")

    deliver(
      employer,
      dgettext("emails", "Interview Cancellation Confirmed"),
      employer_html_body,
      employer_text_body
    )

    {:ok, :cancellation_emails_sent}
  end

  @spec deliver_interview_updated(BemedaPersonal.Scheduling.Interview.t()) :: {:ok, any()}
  def deliver_interview_updated(%BemedaPersonal.Scheduling.Interview{} = interview) do
    interview = preload_interview_associations(interview)

    job_seeker = interview.job_application.user
    company = interview.job_application.job_posting.company

    EmailDelivery.put_locale(job_seeker)

    text_body = """
    #{dgettext("emails", "Hello")} #{job_seeker.first_name},

    #{dgettext("emails", "Your interview details have been updated.")}

    #{dgettext("emails", "Position")}: #{interview.job_application.job_posting.title}
    #{dgettext("emails", "Company")}: #{company.name}
    #{dgettext("emails", "New Date")}: #{format_interview_date(interview)}
    #{dgettext("emails", "New Time")}: #{format_interview_time(interview)}
    #{dgettext("emails", "Meeting Link")}: #{interview.meeting_link}

    #{dgettext("emails", "Please note the updated details.")}

    #{dgettext("emails", "Best regards")},
    #{company.name}
    """

    html_body = String.replace(text_body, "\n", "<br>")

    deliver(job_seeker, dgettext("emails", "Interview Updated"), html_body, text_body)

    {:ok, :update_email_sent}
  end

  # Private helper functions
  defp deliver(recipient, subject, html_body, text_body) do
    EmailDelivery.deliver(recipient, subject, html_body, text_body)
  end

  defp preload_interview_associations(interview) do
    BemedaPersonal.Repo.preload(interview, [
      :created_by,
      job_application: [
        :user,
        job_posting: [company: :admin_user]
      ]
    ])
  end

  defp format_interview_date(interview) do
    # Simple European date format: DD.MM.YYYY
    interview.scheduled_at
    |> DateTime.to_date()
    |> Calendar.strftime("%d.%m.%Y")
  end

  defp format_interview_time(interview) do
    # Format: HH:MM - HH:MM UTC (simplified)
    start_time =
      interview.scheduled_at
      |> DateTime.to_time()
      |> Time.to_string()
      |> String.slice(0, 5)

    end_time =
      interview.end_time
      |> DateTime.to_time()
      |> Time.to_string()
      |> String.slice(0, 5)

    timezone_display = if interview.timezone, do: interview.timezone, else: "UTC"

    "#{start_time} - #{end_time} #{timezone_display}"
  end

  defp calculate_duration(interview) do
    minutes = DateTime.diff(interview.end_time, interview.scheduled_at, :minute)

    cond do
      minutes < 60 ->
        "#{minutes} #{ngettext("minute", "minutes", minutes, gettext_backend: BemedaPersonalWeb.Gettext)}"

      minutes == 60 ->
        "1 #{gettext("hour", gettext_backend: BemedaPersonalWeb.Gettext)}"

      true ->
        "#{div(minutes, 60)} #{ngettext("hour", "hours", div(minutes, 60), gettext_backend: BemedaPersonalWeb.Gettext)}"
    end
  end

  defp format_time_until(scheduled_at) do
    now = DateTime.utc_now()
    minutes = DateTime.diff(scheduled_at, now, :minute)

    cond do
      minutes <= 60 ->
        "#{minutes} #{ngettext("minute", "minutes", minutes, gettext_backend: BemedaPersonalWeb.Gettext)}"

      minutes <= 1440 ->
        "#{div(minutes, 60)} #{ngettext("hour", "hours", div(minutes, 60), gettext_backend: BemedaPersonalWeb.Gettext)}"

      true ->
        "#{div(minutes, 1440)} #{ngettext("day", "days", div(minutes, 1440), gettext_backend: BemedaPersonalWeb.Gettext)}"
    end
  end
end
