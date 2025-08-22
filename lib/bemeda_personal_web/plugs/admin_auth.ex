defmodule BemedaPersonalWeb.AdminAuth do
  @moduledoc """
  Provides HTTP Basic Authentication for admin routes.

  Credentials are configured in config/config.exs with defaults:
  - username: "admin"
  - password: "admin"

  Can be overridden via environment variables in runtime.exs:
  - ADMIN_USERNAME
  - ADMIN_PASSWORD
  """

  import Plug.Conn

  require Logger

  @realm "Admin Dashboard"

  @spec init(keyword()) :: keyword()
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, _opts) do
    case authenticate(conn) do
      :ok ->
        conn

      :error ->
        log_unauthorized_attempt(conn)
        send_unauthorized_response(conn)
    end
  end

  @spec authenticate(Plug.Conn.t()) :: :ok | :error
  defp authenticate(conn) do
    username = Application.get_env(:bemeda_personal, :admin)[:username]
    password = Application.get_env(:bemeda_personal, :admin)[:password]

    with {:ok, credentials} <- extract_credentials(conn),
         :ok <- verify_credentials(credentials, username, password) do
      :ok
    else
      _error -> :error
    end
  end

  @spec extract_credentials(Plug.Conn.t()) :: {:ok, {String.t(), String.t()}} | :error
  defp extract_credentials(conn) do
    case get_req_header(conn, "authorization") do
      ["Basic " <> encoded] -> decode_basic_auth(encoded)
      _no_auth -> :error
    end
  end

  @spec decode_basic_auth(String.t()) :: {:ok, {String.t(), String.t()}} | :error
  defp decode_basic_auth(encoded) do
    with {:ok, decoded} <- Base.decode64(encoded),
         [username, password] <- String.split(decoded, ":", parts: 2) do
      {:ok, {username, password}}
    else
      _invalid -> :error
    end
  end

  @spec verify_credentials({String.t(), String.t()}, String.t(), String.t()) :: :ok | :error
  defp verify_credentials({provided_username, provided_password}, username, password) do
    if Plug.Crypto.secure_compare(provided_username, username) &&
         Plug.Crypto.secure_compare(provided_password, password) do
      :ok
    else
      :error
    end
  end

  @spec log_unauthorized_attempt(Plug.Conn.t()) :: :ok
  defp log_unauthorized_attempt(conn) do
    remote_ip_string =
      conn.remote_ip
      |> :inet.ntoa()
      |> to_string()

    Logger.warning("Unauthorized admin access attempt from #{remote_ip_string}")
  end

  @spec send_unauthorized_response(Plug.Conn.t()) :: Plug.Conn.t()
  defp send_unauthorized_response(conn) do
    conn
    |> put_resp_header("www-authenticate", "Basic realm=\"#{@realm}\"")
    |> send_resp(401, "Unauthorized")
    |> halt()
  end
end
