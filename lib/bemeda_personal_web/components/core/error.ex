defmodule BemedaPersonalWeb.Components.Core.Error do
  @moduledoc """
  Error handling components and utilities.
  """

  use Phoenix.Component
  use Gettext, backend: BemedaPersonalWeb.Gettext

  import BemedaPersonalWeb.Components.Core.Icon

  @doc """
  Generates a generic error message.
  """
  attr :class, :any, default: nil
  slot :inner_block, required: true

  @spec error(map()) :: Phoenix.LiveView.Rendered.t()
  def error(assigns) do
    assigns =
      assign_new(assigns, :classes, fn ->
        [
          "mt-3 flex gap-3 text-sm leading-6 text-danger-600",
          assigns[:class]
        ]
      end)

    ~H"""
    <p class={@classes}>
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  @spec translate_error({String.t(), Keyword.t()}) :: String.t()
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(BemedaPersonalWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(BemedaPersonalWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  @spec translate_errors(list(), atom()) :: list()
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
