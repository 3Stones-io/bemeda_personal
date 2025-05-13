defmodule BemedaPersonal.Repo.Migrations.CreateEmailCommunications do
  use Ecto.Migration

  def change do
    create table(:email_communications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :subject, :string
      add :body, :text
      add :html_body, :text
      add :status, :string
      add :email_type, :string
      add :recipient_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :sender_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :company_id, references(:companies, on_delete: :nothing, type: :binary_id)

      add :job_application_id,
          references(:job_applications, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:email_communications, [:recipient_id])
    create index(:email_communications, [:sender_id])
    create index(:email_communications, [:company_id])
    create index(:email_communications, [:job_application_id])
  end
end
