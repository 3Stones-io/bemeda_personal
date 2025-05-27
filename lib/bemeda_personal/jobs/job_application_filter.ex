defmodule BemedaPersonal.Jobs.JobApplicationFilter do
  @moduledoc false

  use Ecto.Schema
  use Gettext, backend: BemedaPersonalWeb.Gettext

  import Ecto.Changeset

  alias BemedaPersonal.Jobs.FilterUtils

  @type changeset() :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    field :applicant_name, :string
    field :company_id, Ecto.UUID
    field :date_from, :date
    field :date_to, :date
    field :job_posting_id, Ecto.UUID
    field :job_title, :string
    field :state, :string
    field :tags, {:array, :string}
    field :user_id, Ecto.UUID
  end

  @fields [
    :applicant_name,
    :company_id,
    :date_from,
    :date_to,
    :job_posting_id,
    :job_title,
    :state,
    :tags,
    :user_id
  ]

  @spec changeset(changeset() | map(), map()) :: changeset()
  def changeset(job_application_filter, attrs) do
    job_application_filter
    |> cast(attrs, @fields)
    |> validate_dates()
  end

  defp validate_dates(changeset) do
    date_from = get_field(changeset, :date_from)
    date_to = get_field(changeset, :date_to)

    if date_from && date_to && Date.compare(date_from, date_to) == :gt do
      changeset
      |> add_error(
        :date_from,
        dgettext("validation", "Start date must be before or equal to end date")
      )
      |> add_error(
        :date_to,
        dgettext("validation", "End date must be after or equal to start date")
      )
    else
      changeset
    end
  end

  @spec to_params(changeset()) :: map()
  def to_params(%Ecto.Changeset{valid?: true} = changeset) do
    changeset
    |> FilterUtils.changeset_to_params()
    |> convert_dates_to_strings()
  end

  def to_params(%Ecto.Changeset{valid?: false, changes: changes}) do
    convert_dates_to_strings(changes)
  end

  defp convert_dates_to_strings(params) do
    params
    |> Map.update(:date_from, nil, fn
      nil -> nil
      %Date{} = date -> Date.to_string(date)
    end)
    |> Map.update(:date_to, nil, fn
      nil -> nil
      %Date{} = date -> Date.to_string(date)
    end)
  end
end
