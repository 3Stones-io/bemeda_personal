defmodule BemedaPersonal.Accounts.EmailTemplates.ResetPasswordEmail do
  @moduledoc false

  use Gettext, backend: BemedaPersonalWeb.Gettext

  use MjmlEEx,
    layout: BemedaPersonal.Accounts.EmailTemplates.BaseTemplate,
    mjml_template: "reset_password_email.mjml.eex"
end
