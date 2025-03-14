defmodule BemedaPersonalWeb.CompanyLiveTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.AccountsFixtures

  @update_attrs %{
    name: "some updated name",
    size: "50-500 employees",
    description: "some updated description",
    location: "some updated location",
    industry: "some updated industry",
    website_url: "some updated website_url",
    logo_url: "some updated logo_url"
  }

  setup %{conn: conn} do
    user = user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  defp create_company(%{user: user}) do
    company = company_fixture(%{admin_user: user})
    %{company: company}
  end

  describe "/companies" do
    setup [:create_company]

    test "lists all companies", %{conn: conn, company: company} do
      {:ok, _index_live, html} = live(conn, ~p"/companies")

      assert html =~ "Your Company"
      assert html =~ company.name
    end

    test "can navigate to new company form", %{conn: conn} do
      # Create a user without a company
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, index_live, _html} = live(conn, ~p"/companies")

      assert index_live
             |> element("a", "New Company")
             |> render_click() =~
               "New Company"

      assert_patch(index_live, ~p"/companies/new")
    end

    test "updates company in listing", %{conn: conn, company: company} do
      {:ok, index_live, _html} = live(conn, ~p"/companies")

      assert index_live
             |> element("a", "Edit Company")
             |> render_click() =~
               "Edit Company"

      assert_patch(index_live, ~p"/companies/#{company.id}/edit")

      assert index_live
             |> form("#company-form", company: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/companies")

      html = render(index_live)
      assert html =~ "Success!"
    end
  end
end
