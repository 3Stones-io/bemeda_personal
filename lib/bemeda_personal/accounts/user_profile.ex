defmodule BemedaPersonal.Accounts.UserProfile do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  embedded_schema do
    field :date_of_birth, :date
    field :first_name, :string
    field :gender, Ecto.Enum, values: [:male, :female]
    field :last_name, :string
    field :phone, :string
  end

  @fields [
    :date_of_birth,
    :first_name,
    :gender,
    :last_name,
    :phone
  ]

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(profile, attrs \\ %{}) do
    profile
    |> cast(attrs, @fields)
    |> validate_required([:first_name, :last_name])
    |> validate_length(:first_name, min: 1, max: 255)
    |> validate_length(:last_name, min: 1, max: 255)
  end
end
