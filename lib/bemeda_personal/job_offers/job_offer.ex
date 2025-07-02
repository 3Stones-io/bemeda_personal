defmodule BemedaPersonal.JobOffers.JobOffer do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @statuses [:pending, :extended]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "job_offers" do
    field :contract_generated_at, :utc_datetime
    field :contract_signed_at, :utc_datetime
    belongs_to :job_application, BemedaPersonal.JobApplications.JobApplication
    belongs_to :message, BemedaPersonal.Chat.Message
    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :variables, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(job_offer, attrs) do
    job_offer
    |> cast(attrs, [
      :contract_generated_at,
      :contract_signed_at,
      :job_application_id,
      :status,
      :variables
    ])
    |> validate_required([:job_application_id, :status])
    |> unique_constraint(:job_application_id, name: :job_offers_job_application_id_index)
  end
end
