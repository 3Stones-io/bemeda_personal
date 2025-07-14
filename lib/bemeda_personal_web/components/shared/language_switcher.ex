defmodule BemedaPersonalWeb.Components.Shared.LanguageSwitcher do
  @moduledoc """
  Language switcher component for i18n support.
  """

  use BemedaPersonalWeb, :html

  alias BemedaPersonalWeb.Locale

  @languages %{
    "de" => %{name: "Deutsch", flag: "🇩🇪"},
    "en" => %{name: "English", flag: "🇺🇸"},
    "fr" => %{name: "Français", flag: "🇫🇷"},
    "it" => %{name: "Italiano", flag: "🇮🇹"}
  }

  @doc """
  Returns the available languages filtered by supported locales.
  """
  @spec languages() :: map()
  def languages do
    available_locales = Locale.supported_locales()
    Map.take(@languages, available_locales)
  end

  attr :id, :string, required: true
  attr :locale, :string, required: true

  @spec language_switcher(map()) :: Phoenix.LiveView.Rendered.t()
  def language_switcher(assigns) do
    available_locales = Locale.supported_locales()
    filtered_languages = Map.take(@languages, available_locales)
    assigns = assign(assigns, :languages, filtered_languages)

    ~H"""
    <div class="relative inline-block text-left" phx-click-away={JS.hide(to: "##{@id}")}>
      <div>
        <button
          type="button"
          class="inline-flex items-center justify-center w-full rounded-md border border-gray-300 shadow-sm px-3 py-2 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          phx-click={JS.toggle(to: "##{@id}")}
          aria-expanded="true"
          aria-haspopup="true"
        >
          <span class="mr-2 text-lg">{@languages[@locale].flag}</span>
          <span class="hidden sm:inline">{@languages[@locale].name}</span>
          <.icon name="hero-chevron-down" class="ml-2 -mr-1 h-4 w-4" />
        </button>
      </div>

      <div
        id={@id}
        class={
          [
            "hidden origin-top-right absolute mt-2 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 focus:outline-none z-50",
            # On mobile, make the dropdown full width
            "left-0 right-0 w-auto mx-4 sm:left-auto sm:right-0 sm:w-48 sm:mx-0"
          ]
        }
        role="menu"
        aria-orientation="vertical"
        aria-labelledby="menu-button"
        tabindex="-1"
      >
        <div class="py-1" role="none">
          <button
            :for={{code, info} <- @languages}
            type="button"
            phx-click={JS.navigate(~p"/locale/#{code}")}
            class={[
              "group flex items-center px-4 py-2 text-sm hover:bg-gray-100 w-full text-left",
              @locale == code && "bg-gray-50 text-gray-900",
              @locale != code && "text-gray-700"
            ]}
            role="menuitem"
            tabindex="-1"
          >
            <span class="mr-3 text-lg flex-shrink-0">{info.flag}</span>
            <span class="flex-1">{info.name}</span>
            <.icon :if={@locale == code} name="hero-check" class="ml-auto h-4 w-4 text-indigo-600" />
          </button>
        </div>
      </div>
    </div>
    """
  end
end
