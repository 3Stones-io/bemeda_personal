defmodule BemedaPersonal.Accounts.Address do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  embedded_schema do
    field :city, :string
    field :country, :string
    field :street, :string
    field :zip_code, :string
  end

  @fields [
    :street,
    :city,
    :zip_code,
    :country
  ]

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(address, attrs \\ %{}) do
    address
    |> cast(attrs, @fields)
    |> validate_length(:city, min: 1, max: 100)
    |> validate_length(:country, min: 1, max: 100)
    |> validate_length(:street, min: 1, max: 255)
    |> validate_length(:zip_code, min: 1, max: 20)
  end
end
