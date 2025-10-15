defmodule BemedaPersonal.Accounts.EmailTemplates.MagicLinkEmail do
  @moduledoc false

  use BemedaPersonal.EmailTemplate,
    mjml_template: "magic_link_email.mjml.eex"
end
