defmodule BemedaPersonal.CompanyTemplates.CompanyTemplate do
  @moduledoc """
  Schema for company job offer templates.

  Each company can have multiple templates but only one active template at a time.
  Templates contain DOCX files with variables in [[Variable_Name]] format.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.Media.MediaAsset

  @type attrs :: map()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "company_templates" do
    belongs_to :company, Company
    has_one :media_asset, MediaAsset
    field :name, :string
    field :variables, {:array, :string}, default: []

    field :status, Ecto.Enum,
      values: [:uploading, :processing, :active, :inactive, :failed],
      default: :uploading

    field :error_message, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for company template.

  ## Examples

      iex> changeset(%CompanyTemplate{}, %{name: "Template.docx"})
      %Ecto.Changeset{}
  """
  @spec changeset(t(), attrs()) :: Ecto.Changeset.t()
  def changeset(template, attrs) do
    template
    |> cast(attrs, [
      :error_message,
      :name,
      :status,
      :variables
    ])
    |> validate_required([:name, :status])
    |> validate_length(:name, max: 255)
    |> foreign_key_constraint(:company_id)
    |> unique_constraint(:company_id, name: "company_templates_single_active_index")
  end
end
