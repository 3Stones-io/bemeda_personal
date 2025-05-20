defmodule BemedaPersonal.Accounts.EmailTemplates.EmployerJobApplicationStatusEmail do
  @moduledoc false

  use MjmlEEx,
    layout: BemedaPersonal.Accounts.EmailTemplates.BaseTemplate,
    mjml_template: "employer_job_application_status_email.mjml.eex"
end
