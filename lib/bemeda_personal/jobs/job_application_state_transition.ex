defmodule BemedaPersonal.Jobs.JobApplicationStateTransition do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Jobs.JobApplication

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "job_application_state_transitions" do
    field :from_state, :string
    belongs_to :job_application, JobApplication
    field :notes, :string
    field :to_state, :string
    belongs_to :transitioned_by, User

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(%__MODULE__{} = transition, attrs) do
    transition
    |> cast(attrs, [:from_state, :notes, :to_state])
    |> validate_required([:from_state, :to_state])
  end
end
