defmodule BemedaPersonalWeb.Plugs.MuxSignature do
  @moduledoc false

  import Plug.Conn

  @type conn :: Plug.Conn.t()

  @spec init(Keyword.t()) :: Keyword.t()
  def init([]), do: []

  @spec call(conn(), Keyword.t()) :: conn()
  def call(conn, _opts) do
    with payload <- conn.assigns.raw_body,
         [signature] <- get_req_header(conn, "mux-signature"),
         secret <- Application.get_env(:mux, :webhook_secret),
         :ok <- Mux.Webhooks.verify_header(payload, signature, secret) do
      conn
    else
      _unauthorized ->
        conn
        |> send_resp(:unauthorized, "")
        |> halt()
    end

    conn
  end
end
