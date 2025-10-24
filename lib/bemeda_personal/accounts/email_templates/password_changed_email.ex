defmodule BemedaPersonal.Accounts.EmailTemplates.PasswordChangedEmail do
  @moduledoc false

  use BemedaPersonal.EmailTemplate, mjml_template: "password_changed_email.mjml.eex"
end
