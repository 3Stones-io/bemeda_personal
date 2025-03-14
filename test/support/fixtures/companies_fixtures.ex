defmodule BemedaPersonal.CompaniesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.Companies` context.
  """

  import BemedaPersonal.AccountsFixtures

  @spec company_fixture(map()) :: BemedaPersonal.Companies.Company.t()
  def company_fixture(attrs \\ %{}) do
    # Create a user if not provided
    user =
      if Map.has_key?(attrs, :admin_user) || Map.has_key?(attrs, "admin_user") do
        attrs.admin_user || attrs["admin_user"]
      else
        user_fixture()
      end

    # Remove admin_user_id from attrs as it's now passed separately
    attrs = Map.drop(attrs, [:admin_user_id, "admin_user_id", :admin_user, "admin_user"])

    {:ok, company} =
      attrs
      |> Enum.into(%{
        description: "some description",
        industry: "some industry",
        location: "some location",
        logo_url: "some logo_url",
        name: "some name",
        size: "some size",
        website_url: "some website_url"
      })
      |> then(fn attrs -> BemedaPersonal.Companies.create_company(user, attrs) end)

    company
  end
end
