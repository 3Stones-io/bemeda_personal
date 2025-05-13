defmodule BemedaPersonal.Emails.EmailCommunication do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.Jobs.JobApplication

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "email_communications" do
    field :body, :string
    belongs_to :company, Company
    field :email_type, :string
    field :html_body, :string
    belongs_to :job_application, JobApplication
    belongs_to :recipient, User
    belongs_to :sender, User
    field :status, Ecto.Enum, values: [:sent, :draft, :failed]
    field :subject, :string

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(email_communication, attrs) do
    email_communication
    |> cast(attrs, [
      :body,
      :email_type,
      :html_body,
      :status,
      :subject
    ])
    |> validate_required([:subject, :body, :status, :email_type])
  end
end
