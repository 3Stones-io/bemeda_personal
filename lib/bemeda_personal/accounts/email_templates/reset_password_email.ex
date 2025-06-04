defmodule BemedaPersonal.Accounts.EmailTemplates.ResetPasswordEmail do
  @moduledoc false

  use BemedaPersonal.EmailTemplate, mjml_template: "reset_password_email.mjml.eex"
end
