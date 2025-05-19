defmodule BemedaPersonal.Accounts.EmailTemplates.ConfirmationEmail do
  @moduledoc false

  use MjmlEEx,
    layout: BemedaPersonal.Accounts.EmailTemplates.BaseTemplate,
    mjml_template: "confirmation_email.mjml.eex"
end
