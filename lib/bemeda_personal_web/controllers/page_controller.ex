defmodule BemedaPersonalWeb.PageController do
  use BemedaPersonalWeb, :controller

  @type conn :: Plug.Conn.t()
  @type params :: map()

  @spec home(conn(), params()) :: conn()
  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end
end
