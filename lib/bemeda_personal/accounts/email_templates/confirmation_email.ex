defmodule BemedaPersonal.Accounts.EmailTemplates.ConfirmationEmail do
  @moduledoc false

  use BemedaPersonal.EmailTemplate, mjml_template: "confirmation_email.mjml.eex"
end
