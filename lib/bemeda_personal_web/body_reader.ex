defmodule BemedaPersonalWeb.BodyReader do
  @moduledoc false

  @type conn :: Plug.Conn.t()

  @spec read_body(conn(), Keyword.t()) :: {:ok, binary(), conn()} | {:error, any()}
  def read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    updated_conn = update_in(conn.assigns[:raw_body], &[body | &1 || []])
    {:ok, body, updated_conn}
  end
end
