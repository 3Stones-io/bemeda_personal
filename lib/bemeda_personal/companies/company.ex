defmodule BemedaPersonal.Companies.Company do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Media.MediaAsset

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "companies" do
    belongs_to :admin_user, User
    field :description, :string
    field :hospital_affiliation, :string
    field :industry, :string
    field :location, :string
    has_one :media_asset, MediaAsset
    field :name, :string
    field :organization_type, :string
    field :phone_number, :string
    field :size, :string
    field :website_url, :string

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(company, attrs) do
    company
    |> cast(attrs, [
      :description,
      :hospital_affiliation,
      :industry,
      :location,
      :name,
      :organization_type,
      :phone_number,
      :size,
      :website_url
    ])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_format(:phone_number, ~r/^(\+\d{1,3}\s?)?\d{2,14}$/,
      message: "must be a valid phone number",
      allow_blank: true
    )
    |> validate_format(:website_url, ~r/^https?:\/\//,
      message: "must start with http:// or https://",
      allow_blank: true
    )
    |> unique_constraint(:name)
  end
end
