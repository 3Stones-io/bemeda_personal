defmodule BemedaPersonal.Accounts.EmailTemplates.ConfirmationEmail do
  @moduledoc false

  use Gettext, backend: BemedaPersonalWeb.Gettext

  use MjmlEEx,
    layout: BemedaPersonal.Accounts.EmailTemplates.BaseTemplate,
    mjml_template: "confirmation_email.mjml.eex"
end
