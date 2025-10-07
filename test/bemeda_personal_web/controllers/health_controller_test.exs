defmodule BemedaPersonalWeb.HealthControllerTest do
  use BemedaPersonalWeb.ConnCase, async: false

  describe "GET /health" do
    test "returns cluster info", %{conn: conn} do
      conn = get(conn, ~p"/health")

      assert %{
               "connected_to" => [],
               "hostname" => _hostname,
               "node" => "nonode@nohost",
               "status" => "ok"
             } = json_response(conn, 200)
    end
  end
end
