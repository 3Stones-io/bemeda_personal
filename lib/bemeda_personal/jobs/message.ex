defmodule BemedaPersonal.Jobs.Message do
  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Jobs.JobApplication
  alias BemedaPersonal.Jobs.MuxData

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field :content, :string
    belongs_to :job_application, JobApplication
    embeds_one :mux_data, MuxData, on_replace: :update
    belongs_to :sender, User

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content])
    |> cast_embed(:mux_data)
  end
end
