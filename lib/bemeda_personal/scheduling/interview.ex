defmodule BemedaPersonal.Scheduling.Interview do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.JobApplications.JobApplication

  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "interviews" do
    field :scheduled_at, :utc_datetime
    field :end_time, :utc_datetime
    field :meeting_link, :string
    field :notes, :string
    field :reminder_minutes_before, :integer, default: 30
    field :status, Ecto.Enum, values: [:scheduled, :cancelled, :completed], default: :scheduled
    field :title, :string
    field :cancelled_at, :utc_datetime
    field :cancellation_reason, :string
    field :timezone, :string

    belongs_to :job_application, JobApplication
    belongs_to :created_by, User

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(interview, attrs) do
    interview
    |> cast(attrs, [
      :scheduled_at,
      :end_time,
      :meeting_link,
      :notes,
      :reminder_minutes_before,
      :status,
      :title,
      :timezone,
      :job_application_id,
      :created_by_id
    ])
    |> validate_required([
      :scheduled_at,
      :end_time,
      :meeting_link,
      :timezone,
      :job_application_id,
      :created_by_id
    ])
    |> validate_meeting_link()
    |> validate_time_range()
    |> validate_future_date()
    |> validate_number(:reminder_minutes_before,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 10_080
    )
    |> foreign_key_constraint(:job_application_id)
    |> foreign_key_constraint(:created_by_id)
  end

  @spec update_changeset(t(), map()) :: Ecto.Changeset.t()
  def update_changeset(interview, attrs) do
    changeset =
      cast(interview, attrs, [
        :scheduled_at,
        :end_time,
        :meeting_link,
        :notes,
        :reminder_minutes_before,
        :status,
        :title,
        :timezone
      ])

    # Only validate required fields if they're being changed or if they're missing
    required_fields = maybe_require_datetime_fields([:meeting_link, :timezone], changeset, attrs)

    changeset
    |> validate_required(required_fields)
    |> validate_meeting_link()
    |> validate_time_range()
    |> validate_future_date()
    |> validate_number(:reminder_minutes_before,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 10_080
    )
  end

  defp maybe_require_datetime_fields(base_required, changeset, attrs) do
    # Only require datetime fields if they're being updated or if they're nil in the database
    datetime_fields = [:scheduled_at, :end_time]

    Enum.reduce(datetime_fields, base_required, fn field, acc ->
      field_string = Atom.to_string(field)

      if Map.has_key?(attrs, field_string) or is_nil(Map.get(changeset.data, field)) do
        [field | acc]
      else
        acc
      end
    end)
  end

  @spec cancel_changeset(t(), map()) :: Ecto.Changeset.t()
  def cancel_changeset(interview, attrs) do
    interview
    |> cast(attrs, [:cancellation_reason])
    |> put_change(:status, :cancelled)
    |> put_change(:cancelled_at, DateTime.utc_now(:second))
    |> validate_required([:cancellation_reason])
  end

  defp validate_meeting_link(changeset) do
    validate_change(changeset, :meeting_link, fn :meeting_link, link ->
      if String.match?(link, ~r/^https?:\/\/.+/) do
        []
      else
        [meeting_link: "must be a valid URL starting with http:// or https://"]
      end
    end)
  end

  defp validate_time_range(changeset) do
    validate_change(changeset, :end_time, fn :end_time, end_time ->
      validate_end_time_after_start(changeset, end_time)
    end)
  end

  defp validate_end_time_after_start(changeset, end_time) do
    case get_change(changeset, :scheduled_at) do
      nil ->
        []

      scheduled_at ->
        if DateTime.compare(end_time, scheduled_at) == :gt do
          []
        else
          [end_time: "must be after the scheduled start time"]
        end
    end
  end

  defp validate_future_date(changeset) do
    validate_change(changeset, :scheduled_at, fn :scheduled_at, scheduled_at ->
      if DateTime.compare(scheduled_at, DateTime.utc_now()) == :gt do
        []
      else
        [scheduled_at: "must be in the future"]
      end
    end)
  end
end
