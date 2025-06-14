defmodule BemedaPersonal.CompanyTemplatesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.CompanyTemplates` context.
  """

  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.CompanyTemplates
  alias BemedaPersonal.CompanyTemplates.CompanyTemplate

  @type attrs :: map()
  @type company :: Company.t()
  @type template :: CompanyTemplate.t()

  @doc """
  Generate a company template.
  """
  @spec template_fixture(company(), attrs()) :: template()
  def template_fixture(%Company{} = company, attrs \\ %{}) do
    default_attrs = %{
      name: "test_template.docx",
      status: :active,
      variables: []
    }

    attrs = Enum.into(attrs, default_attrs)

    {:ok, template} = CompanyTemplates.create_template(company, attrs)
    template
  end
end
