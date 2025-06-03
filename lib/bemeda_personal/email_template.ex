defmodule BemedaPersonal.EmailTemplate do
  @moduledoc false

  defmacro __using__(opts) do
    mjml_template = Keyword.fetch!(opts, :mjml_template)

    quote do
      use Gettext, backend: BemedaPersonalWeb.Gettext

      use MjmlEEx,
        layout: BemedaPersonal.Accounts.EmailTemplates.BaseTemplate,
        mjml_template: unquote(mjml_template)
    end
  end
end
