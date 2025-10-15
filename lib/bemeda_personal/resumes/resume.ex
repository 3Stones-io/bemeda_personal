defmodule BemedaPersonal.Resumes.Resume do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Resumes.Education
  alias BemedaPersonal.Resumes.WorkExperience
  alias BemedaPersonal.Utils

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "resumes" do
    field :contact_email, :string
    has_many :educations, Education
    field :headline, :string
    field :is_public, :boolean, default: false
    field :phone_number, :string
    field :summary, :string
    belongs_to :user, User
    field :website_url, :string
    has_many :work_experiences, WorkExperience

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(resume, attrs \\ %{}) do
    resume
    |> cast(attrs, [
      :headline,
      :summary,
      :is_public,
      :contact_email,
      :phone_number,
      :website_url
    ])
    |> Utils.validate_e164_phone_number(:phone_number)
  end
end
