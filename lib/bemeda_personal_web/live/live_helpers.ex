defmodule BemedaPersonalWeb.LiveHelpers do
  @moduledoc """
  Hooks and other helpers for LiveViews.
  """
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonalWeb.Locale
  alias Phoenix.LiveView.Socket

  @type socket :: Socket.t()

  @spec on_mount(atom(), map(), map(), socket()) :: {:cont, socket()}
  def on_mount(:assign_locale, _params, session, socket) do
    locale = Map.get(session, "locale", Locale.default_locale())

    Gettext.put_locale(BemedaPersonalWeb.Gettext, locale)

    {:cont, assign(socket, :locale, locale)}
  end
end
