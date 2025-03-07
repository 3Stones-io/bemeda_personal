defmodule BemedaPersonal.Resumes.Resume do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Resumes.Education
  alias BemedaPersonal.Resumes.WorkExperience

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "resumes" do
    field :contact_email, :string
    field :headline, :string
    field :is_public, :boolean, default: false
    field :location, :string
    field :phone_number, :string
    field :summary, :string
    field :website_url, :string

    belongs_to :user, User
    has_many :educations, Education
    has_many :work_experiences, WorkExperience

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(resume, attrs \\ %{}) do
    resume
    |> cast(attrs, [
      :headline,
      :summary,
      :location,
      :is_public,
      :contact_email,
      :phone_number,
      :website_url,
      :user_id
    ])
    |> unique_constraint(:user_id)
  end
end
