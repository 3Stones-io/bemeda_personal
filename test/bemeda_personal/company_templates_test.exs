defmodule BemedaPersonal.CompanyTemplatesTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.CompanyTemplatesFixtures

  alias BemedaPersonal.CompanyTemplates
  alias BemedaPersonal.CompanyTemplates.CompanyTemplate

  describe "create_template/2" do
    test "creates template with valid attributes" do
      user = user_fixture()
      company = company_fixture(user)

      attrs = %{name: "template.docx", status: :active}

      assert {:ok, %CompanyTemplate{} = template} =
               CompanyTemplates.create_template(company, attrs)

      assert template.company_id == company.id
      assert template.name == "template.docx"
      assert template.status == :active
    end

    test "returns error with invalid attributes" do
      user = user_fixture()
      company = company_fixture(user)

      assert {:error, %Ecto.Changeset{}} =
               CompanyTemplates.create_template(company, %{status: :active})
    end
  end

  describe "get_active_template/1" do
    test "returns active template for company" do
      user = user_fixture()
      company = company_fixture(user)
      template = template_fixture(company, %{status: :active})

      assert found = CompanyTemplates.get_active_template(company.id)
      assert found.id == template.id
    end

    test "returns nil when no active template" do
      user = user_fixture()
      company = company_fixture(user)
      _template = template_fixture(company, %{status: :inactive})

      refute CompanyTemplates.get_active_template(company.id)
    end

    test "enforces unique constraint for active templates" do
      user = user_fixture()
      company = company_fixture(user)

      _first_template = template_fixture(company, %{status: :active})

      assert {:error, changeset} =
               CompanyTemplates.create_template(company, %{
                 name: "second_template.docx",
                 status: :active
               })

      assert "has already been taken" in errors_on(changeset).company_id
    end

    test "returns nil for non-existent company" do
      refute CompanyTemplates.get_active_template(Ecto.UUID.generate())
    end
  end

  describe "replace_active_template/2" do
    test "creates first active template when none exists" do
      user = user_fixture()
      company = company_fixture(user)

      attrs = %{
        name: "first_template.docx"
      }

      assert {:ok, template} = CompanyTemplates.replace_active_template(company, attrs)
      assert template.status == :active
      assert template.name == "first_template.docx"

      active_template = CompanyTemplates.get_active_template(company.id)
      assert active_template.id == template.id
    end

    test "replaces existing active template" do
      user = user_fixture()
      company = company_fixture(user)

      {:ok, first_template} =
        CompanyTemplates.create_template(company, %{
          name: "first_template.docx",
          status: :active
        })

      assert first_template.status == :active

      active_template = CompanyTemplates.get_active_template(company.id)
      assert active_template.id == first_template.id

      attrs = %{
        name: "second_template.docx"
      }

      assert {:ok, second_template} = CompanyTemplates.replace_active_template(company, attrs)
      assert second_template.status == :active
      assert second_template.name == "second_template.docx"

      new_active_template = CompanyTemplates.get_active_template(company.id)
      assert new_active_template.id == second_template.id

      updated_first_template = Repo.get(CompanyTemplate, first_template.id)
      assert updated_first_template.status == :inactive
    end

    test "handles validation errors when creating new template" do
      user = user_fixture()
      company = company_fixture(user)

      attrs = %{
        name: nil
      }

      assert {:error, _changeset} = CompanyTemplates.replace_active_template(company, attrs)
    end
  end

  describe "delete_template/1" do
    test "deletes template successfully" do
      user = user_fixture()
      company = company_fixture(user)
      template = template_fixture(company, %{name: "to_delete.docx"})

      assert {:ok, deleted_template} = CompanyTemplates.delete_template(template)
      assert deleted_template.id == template.id
      refute CompanyTemplates.get_active_template(company.id)
    end
  end
end
