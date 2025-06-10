defmodule BemedaPersonal.Chat.Message do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.Media.MediaAsset

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field :content, :string
    belongs_to :job_application, JobApplication
    has_one :media_asset, MediaAsset
    belongs_to :sender, User
    field :type, Ecto.Enum, values: [:status_update, :user], default: :user

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(%__MODULE__{} = message, attrs) do
    message
    |> cast(attrs, [:content, :type])
    |> update_change(:content, &maybe_trim/1)
    |> maybe_validate_content_required(attrs)
  end

  defp maybe_validate_content_required(changeset, attrs) do
    if Map.has_key?(attrs, "content") or Map.has_key?(attrs, :content) do
      validate_required(changeset, [:content], message: "cannot be blank")
    else
      changeset
    end
  end

  defp maybe_trim(nil), do: nil
  defp maybe_trim(string), do: String.trim(string)
end
