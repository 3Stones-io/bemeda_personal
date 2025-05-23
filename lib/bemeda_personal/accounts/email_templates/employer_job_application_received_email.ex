defmodule BemedaPersonal.Accounts.EmailTemplates.EmployerJobApplicationReceivedEmail do
  @moduledoc false

  use MjmlEEx,
    layout: BemedaPersonal.Accounts.EmailTemplates.BaseTemplate,
    mjml_template: "employer_job_application_received_email.mjml.eex"
end
