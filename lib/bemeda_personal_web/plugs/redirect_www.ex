defmodule BemedaPersonalWeb.Plugs.RedirectWww do
  @moduledoc """
  Plug for redirecting www domains to naked domains.
  """

  import Plug.Conn

  @type conn() :: Plug.Conn.t()
  @type opts() :: any()

  @spec init(opts()) :: opts()
  def init(opts), do: opts

  @spec call(conn(), opts()) :: conn()
  def call(conn, _opts) do
    case get_req_header(conn, "host") do
      ["www." <> naked_domain] ->
        redirect_to_naked_domain(conn, naked_domain)

      _other ->
        conn
    end
  end

  @spec redirect_to_naked_domain(conn(), String.t()) :: conn()
  defp redirect_to_naked_domain(conn, naked_domain) do
    scheme = if conn.scheme == :https, do: "https", else: "http"
    url = "#{scheme}://#{naked_domain}#{conn.request_path}"

    full_url =
      case conn.query_string do
        "" -> url
        query_string -> "#{url}?#{query_string}"
      end

    conn
    |> put_status(:moved_permanently)
    |> put_resp_header("location", full_url)
    |> send_resp(301, "")
    |> halt()
  end
end
