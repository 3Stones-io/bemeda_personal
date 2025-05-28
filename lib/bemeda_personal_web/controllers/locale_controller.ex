defmodule BemedaPersonalWeb.LocaleController do
  use BemedaPersonalWeb, :controller

  alias BemedaPersonal.Accounts
  alias BemedaPersonalWeb.Locale

  @type conn() :: Plug.Conn.t()

  @spec set(conn(), map()) :: conn()
  def set(conn, %{"locale" => locale}) do
    validated_locale =
      if locale in Locale.supported_locales(), do: locale, else: Locale.default_locale()

    if current_user = conn.assigns[:current_user] do
      Accounts.update_user_locale(current_user, %{locale: validated_locale})
    end

    conn
    |> put_session(:locale, validated_locale)
    |> redirect(to: get_referer_or_default(conn))
  end

  defp get_referer_or_default(conn) do
    with [referer] <- get_req_header(conn, "referer"),
         %URI{path: path, query: query} <- URI.parse(referer),
         query <- if(query, do: "?#{query}", else: "") do
      "#{path}#{query}"
    else
      _reason -> ~p"/"
    end
  end
end
