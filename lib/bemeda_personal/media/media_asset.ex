defmodule BemedaPersonal.Media.MediaAsset do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Chat.Message
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.CompanyTemplates.CompanyTemplate
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.JobPostings.JobPosting

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "media_assets" do
    belongs_to :company, Company
    belongs_to :company_template, CompanyTemplate
    field :file_name, :string
    belongs_to :job_application, JobApplication
    belongs_to :job_posting, JobPosting
    belongs_to :message, Message
    field :status, Ecto.Enum, values: [:pending, :uploaded, :failed]
    field :type, :string
    field :upload_id, Ecto.UUID

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(%__MODULE__{} = media_asset, attrs) do
    cast(media_asset, attrs, [:company_template_id, :file_name, :status, :type, :upload_id])
  end
end
