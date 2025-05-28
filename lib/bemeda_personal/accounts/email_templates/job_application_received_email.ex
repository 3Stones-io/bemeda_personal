defmodule BemedaPersonal.Accounts.EmailTemplates.JobApplicationReceivedEmail do
  @moduledoc false

  use Gettext, backend: BemedaPersonalWeb.Gettext

  use MjmlEEx,
    layout: BemedaPersonal.Accounts.EmailTemplates.BaseTemplate,
    mjml_template: "job_application_received_email.mjml.eex"
end
