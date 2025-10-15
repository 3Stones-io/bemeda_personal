defmodule BemedaPersonal.Companies.Company do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies.Enums
  alias BemedaPersonal.Media.MediaAsset
  alias BemedaPersonal.Utils

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "companies" do
    belongs_to :admin_user, User
    field :address, :string
    field :city, :string
    field :description, :string
    field :hospital_affiliation, :string
    field :industry, :string
    field :location, Ecto.Enum, values: Enums.locations()
    has_one :media_asset, MediaAsset
    field :name, :string
    field :organization_type, Ecto.Enum, values: Enums.organization_types()
    field :phone_number, :string
    field :postal_code, :string
    field :size, :string
    field :website_url, :string

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(company, attrs) do
    company
    |> cast(attrs, [
      :address,
      :city,
      :description,
      :hospital_affiliation,
      :industry,
      :location,
      :name,
      :organization_type,
      :phone_number,
      :postal_code,
      :size,
      :website_url
    ])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 255)
    |> Utils.validate_e164_phone_number(:phone_number)
    |> validate_format(:website_url, ~r/^https?:\/\//,
      message: "must start with http:// or https://",
      allow_blank: true
    )
    |> unique_constraint(:name)
  end
end
