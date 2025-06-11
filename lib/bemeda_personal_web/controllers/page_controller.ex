defmodule BemedaPersonalWeb.PageController do
  use BemedaPersonalWeb, :controller

  @type conn :: Plug.Conn.t()
  @type params :: map()

  @spec home(conn(), params()) :: conn()
  def home(conn, _params) do
    case conn.assigns[:current_user] do
      %{user_type: :employer} ->
        redirect(conn, to: ~p"/company")

      %{user_type: :job_seeker} ->
        redirect(conn, to: ~p"/jobs")

      _other ->
        render(conn, :home, layout: false)
    end
  end
end
