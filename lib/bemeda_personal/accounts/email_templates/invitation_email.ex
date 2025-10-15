defmodule BemedaPersonal.Accounts.EmailTemplates.InvitationEmail do
  @moduledoc false

  use BemedaPersonal.EmailTemplate,
    mjml_template: "invitation_email.mjml.eex"
end
