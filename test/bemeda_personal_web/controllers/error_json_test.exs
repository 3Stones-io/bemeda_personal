defmodule BemedaPersonalWeb.ErrorJSONTest do
  use BemedaPersonalWeb.ConnCase, async: false

  test "renders 404" do
    assert BemedaPersonalWeb.ErrorJSON.render("404.json", %{}) == %{
             errors: %{detail: "Not Found"}
           }
  end

  test "renders 500" do
    assert BemedaPersonalWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
