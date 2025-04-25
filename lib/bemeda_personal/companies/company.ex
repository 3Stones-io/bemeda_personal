defmodule BemedaPersonal.Companies.Company do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Accounts.User

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "companies" do
    belongs_to :admin_user, User
    field :description, :string
    field :industry, :string
    field :location, :string
    field :logo_url, :string
    field :name, :string
    field :size, :string
    field :website_url, :string
    field :average_rating, :decimal

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(company, attrs) do
    company
    |> cast(attrs, [
      :name,
      :description,
      :industry,
      :size,
      :website_url,
      :location,
      :logo_url
    ])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 255)
    |> unique_constraint(:name)
  end

  @doc """
  A company changeset for updating the average rating.
  """
  @spec average_rating_changeset(t() | changeset(), attrs()) :: changeset()
  def average_rating_changeset(company, attrs) do
    cast(company, attrs, [:average_rating])
  end
end
