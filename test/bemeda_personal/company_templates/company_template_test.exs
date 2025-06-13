defmodule BemedaPersonal.CompanyTemplates.CompanyTemplateTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures

  alias BemedaPersonal.CompanyTemplates
  alias BemedaPersonal.CompanyTemplates.CompanyTemplate

  describe "changeset/2" do
    test "valid changeset with required fields" do
      attrs = %{
        name: "template.docx",
        status: :active
      }

      changeset = CompanyTemplate.changeset(%CompanyTemplate{}, attrs)

      assert changeset.valid?
      assert get_change(changeset, :name) == "template.docx"
      assert get_field(changeset, :status) == :active
    end

    test "invalid changeset without required fields" do
      changeset = CompanyTemplate.changeset(%CompanyTemplate{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "invalid changeset with invalid status" do
      attrs = %{
        name: "template.docx",
        status: :invalid_status
      }

      changeset = CompanyTemplate.changeset(%CompanyTemplate{}, attrs)

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).status
    end

    test "valid changeset with all statuses" do
      for status <- [:active, :inactive] do
        attrs = %{
          name: "template.docx",
          status: status
        }

        changeset = CompanyTemplate.changeset(%CompanyTemplate{}, attrs)
        assert changeset.valid?, "Status #{status} should be valid"
      end
    end

    test "changeset with optional fields" do
      attrs = %{
        name: "template.docx",
        status: :active,
        variables: ["name", "position"],
        error_message: "Some error"
      }

      changeset = CompanyTemplate.changeset(%CompanyTemplate{}, attrs)

      assert changeset.valid?
      assert get_change(changeset, :variables) == ["name", "position"]
      assert get_change(changeset, :error_message) == "Some error"
    end

    test "changeset does not trim whitespace from name" do
      attrs = %{
        name: "  template.docx  ",
        status: :active
      }

      changeset = CompanyTemplate.changeset(%CompanyTemplate{}, attrs)

      assert changeset.valid?
      assert get_change(changeset, :name) == "  template.docx  "
    end

    test "changeset validates name length" do
      long_name = String.duplicate("a", 256)

      attrs = %{
        name: long_name,
        status: :active
      }

      changeset = CompanyTemplate.changeset(%CompanyTemplate{}, attrs)

      refute changeset.valid?
      assert "should be at most 255 character(s)" in errors_on(changeset).name
    end

    test "changeset validates variables is a list" do
      attrs = %{
        name: "template.docx",
        status: :active,
        variables: "not a list"
      }

      changeset = CompanyTemplate.changeset(%CompanyTemplate{}, attrs)

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).variables
    end
  end

  describe "database constraints" do
    test "allows multiple templates per company" do
      user = user_fixture()
      company = company_fixture(user)

      attrs1 = %{
        name: "template1.docx",
        status: :inactive
      }

      attrs2 = %{
        name: "template2.docx",
        status: :inactive
      }

      assert {:ok, _template1} = CompanyTemplates.create_template(company, attrs1)
      assert {:ok, _template2} = CompanyTemplates.create_template(company, attrs2)
    end

    test "enforces unique active template per company constraint" do
      user = user_fixture()
      company = company_fixture(user)

      attrs1 = %{
        name: "template1.docx",
        status: :active
      }

      assert {:ok, _template1} = CompanyTemplates.create_template(company, attrs1)

      attrs2 = %{
        name: "template2.docx",
        status: :active
      }

      assert {:error, changeset} = CompanyTemplates.create_template(company, attrs2)
      assert "has already been taken" in errors_on(changeset).company_id
    end
  end
end
