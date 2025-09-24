defmodule BemedaPersonal.Scheduling.InterviewTest do
  use BemedaPersonal.DataCase, async: true

  alias BemedaPersonal.Scheduling.Interview

  describe "changeset/2" do
    test "valid changeset with valid attributes" do
      attrs = %{
        scheduled_at: DateTime.add(DateTime.utc_now(), 1, :day),
        end_time:
          DateTime.utc_now()
          |> DateTime.add(1, :day)
          |> DateTime.add(60, :minute),
        meeting_link: "https://zoom.us/j/123456789",
        timezone: "Europe/Zurich",
        job_application_id: Ecto.UUID.generate(),
        created_by_id: Ecto.UUID.generate(),
        notes: "First interview"
      }

      changeset = Interview.changeset(%Interview{}, attrs)

      assert changeset.valid?
    end

    test "invalid changeset with missing required fields" do
      changeset = Interview.changeset(%Interview{}, %{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               scheduled_at: ["can't be blank"],
               end_time: ["can't be blank"],
               meeting_link: ["can't be blank"],
               timezone: ["can't be blank"],
               job_application_id: ["can't be blank"],
               created_by_id: ["can't be blank"]
             }
    end

    test "invalid meeting_link format" do
      attrs = %{
        scheduled_at: DateTime.add(DateTime.utc_now(), 1, :day),
        end_time:
          DateTime.utc_now()
          |> DateTime.add(1, :day)
          |> DateTime.add(60, :minute),
        meeting_link: "invalid-url",
        timezone: "Europe/Zurich",
        job_application_id: Ecto.UUID.generate(),
        created_by_id: Ecto.UUID.generate()
      }

      changeset = Interview.changeset(%Interview{}, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               meeting_link: ["must be a valid URL starting with http:// or https://"]
             }
    end

    test "end_time must be after scheduled_at" do
      now = DateTime.utc_now()

      attrs = %{
        scheduled_at: DateTime.add(now, 2, :hour),
        # Earlier than scheduled_at
        end_time: DateTime.add(now, 1, :hour),
        meeting_link: "https://zoom.us/j/123456789",
        timezone: "Europe/Zurich",
        job_application_id: Ecto.UUID.generate(),
        created_by_id: Ecto.UUID.generate()
      }

      changeset = Interview.changeset(%Interview{}, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               end_time: ["must be after the scheduled start time"]
             }
    end

    test "scheduled_at must be in the future" do
      past_time = DateTime.add(DateTime.utc_now(), -1, :hour)

      attrs = %{
        scheduled_at: past_time,
        end_time: DateTime.add(past_time, 1, :hour),
        meeting_link: "https://zoom.us/j/123456789",
        timezone: "Europe/Zurich",
        job_application_id: Ecto.UUID.generate(),
        created_by_id: Ecto.UUID.generate()
      }

      changeset = Interview.changeset(%Interview{}, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               scheduled_at: ["must be in the future"]
             }
    end

    test "reminder_minutes_before validates range" do
      attrs = %{
        scheduled_at: DateTime.add(DateTime.utc_now(), 1, :day),
        end_time:
          DateTime.utc_now()
          |> DateTime.add(1, :day)
          |> DateTime.add(60, :minute),
        meeting_link: "https://zoom.us/j/123456789",
        timezone: "Europe/Zurich",
        job_application_id: Ecto.UUID.generate(),
        created_by_id: Ecto.UUID.generate(),
        # Invalid negative value
        reminder_minutes_before: -1
      }

      changeset = Interview.changeset(%Interview{}, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               reminder_minutes_before: ["must be greater than or equal to 0"]
             }
    end

    test "reminder_minutes_before validates maximum" do
      attrs = %{
        scheduled_at: DateTime.add(DateTime.utc_now(), 1, :day),
        end_time:
          DateTime.utc_now()
          |> DateTime.add(1, :day)
          |> DateTime.add(60, :minute),
        meeting_link: "https://zoom.us/j/123456789",
        timezone: "Europe/Zurich",
        job_application_id: Ecto.UUID.generate(),
        created_by_id: Ecto.UUID.generate(),
        # Over 1 week (10080 minutes)
        reminder_minutes_before: 11_000
      }

      changeset = Interview.changeset(%Interview{}, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               reminder_minutes_before: ["must be less than or equal to 10080"]
             }
    end
  end

  describe "cancel_changeset/2" do
    test "valid cancel changeset" do
      interview = %Interview{status: :scheduled}
      attrs = %{cancellation_reason: "Meeting no longer needed"}

      changeset = Interview.cancel_changeset(interview, attrs)

      assert changeset.valid?
      assert get_change(changeset, :status) == :cancelled
      assert get_change(changeset, :cancellation_reason) == "Meeting no longer needed"
      assert get_change(changeset, :cancelled_at) != nil
    end

    test "invalid cancel changeset without reason" do
      interview = %Interview{status: :scheduled}
      changeset = Interview.cancel_changeset(interview, %{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               cancellation_reason: ["can't be blank"]
             }
    end
  end
end
