defmodule BemedaPersonal.Accounts.EmailTemplates.NewMessageEmail do
  @moduledoc false

  use Gettext, backend: BemedaPersonalWeb.Gettext

  use MjmlEEx,
    layout: BemedaPersonal.Accounts.EmailTemplates.BaseTemplate,
    mjml_template: "new_message_email.mjml.eex"
end
