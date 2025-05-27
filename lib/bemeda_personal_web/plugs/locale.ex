defmodule BemedaPersonalWeb.Locale do
  @moduledoc """
  Plug for handling locale detection.
  """

  import Plug.Conn

  alias BemedaPersonal.Accounts.User
  alias Plug.Conn

  @type conn() :: Plug.Conn.t()
  @type locale() :: String.t()

  @default_locale Application.compile_env!(:bemeda_personal, BemedaPersonalWeb.Gettext)[
                    :default_locale
                  ]
  @supported_locales Application.compile_env!(:bemeda_personal, BemedaPersonalWeb.Gettext)[
                       :locales
                     ]

  @doc """
  Get the default locale from the application config.
  """
  @spec default_locale() :: locale()
  def default_locale, do: @default_locale

  @doc """
  Get supported locales from the application config.
  """
  @spec supported_locales() :: [locale()]
  def supported_locales, do: @supported_locales

  @spec init(any()) :: any()
  def init(default), do: default

  @spec call(conn(), any()) :: conn()
  def call(conn, _default) do
    locale =
      get_locale_from_session(conn) ||
        get_locale_from_user(conn) ||
        @default_locale

    Gettext.put_locale(BemedaPersonalWeb.Gettext, locale)

    conn
    |> assign(:locale, locale)
    |> put_session(:locale, locale)
  end

  defp get_locale_from_session(conn) do
    locale = get_session(conn, :locale)

    if locale in supported_locales() do
      to_string(locale)
    end
  end

  defp get_locale_from_user(%Conn{assigns: %{current_user: %User{locale: locale}}}) do
    to_string(locale)
  end

  defp get_locale_from_user(_conn), do: nil
end
