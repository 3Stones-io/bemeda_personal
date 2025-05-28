defmodule BemedaPersonal.Accounts.EmailTemplates.JobApplicationStatusEmail do
  @moduledoc false

  use Gettext, backend: BemedaPersonalWeb.Gettext

  use MjmlEEx,
    layout: BemedaPersonal.Accounts.EmailTemplates.BaseTemplate,
    mjml_template: "job_application_status_email.mjml.eex"
end
