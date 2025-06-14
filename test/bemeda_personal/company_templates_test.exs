defmodule BemedaPersonal.CompanyTemplatesTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.CompanyTemplatesFixtures
  import Ecto.Query

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
      assert updated_first_template.status == :uploading
    end

    test "creates template with non-active status without deactivating existing" do
      user = user_fixture()
      company = company_fixture(user)

      template_fixture(company, %{name: "active.docx", status: :active})

      attrs = %{
        name: "processing_template.docx",
        status: :processing
      }

      assert {:ok, processing_template} = CompanyTemplates.replace_active_template(company, attrs)
      assert processing_template.status == :processing
      assert processing_template.name == "processing_template.docx"

      active_template = CompanyTemplates.get_active_template(company.id)
      assert active_template.name == "active.docx"
      assert active_template.status == :active
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

  describe "get_current_template/1" do
    test "returns processing template when both processing and active exist" do
      user = user_fixture()
      company = company_fixture(user)

      _active_template = template_fixture(company, %{name: "active.docx", status: :active})

      processing_template =
        template_fixture(company, %{name: "processing.docx", status: :processing})

      current = CompanyTemplates.get_current_template(company.id)
      assert current.id == processing_template.id
      assert current.status == :processing
    end

    test "returns active template when no processing template exists" do
      user = user_fixture()
      company = company_fixture(user)

      active_template = template_fixture(company, %{name: "active.docx", status: :active})

      current = CompanyTemplates.get_current_template(company.id)
      assert current.id == active_template.id
      assert current.status == :active
    end

    test "ignores failed templates and returns active template" do
      user = user_fixture()
      company = company_fixture(user)

      active_template = template_fixture(company, %{name: "active.docx", status: :active})
      _failed_template = template_fixture(company, %{name: "failed.docx", status: :failed})

      current = CompanyTemplates.get_current_template(company.id)
      assert current.id == active_template.id
      assert current.status == :active
    end

    test "returns nil when no templates exist" do
      user = user_fixture()
      company = company_fixture(user)

      refute CompanyTemplates.get_current_template(company.id)
    end

    test "returns most recent processing template when multiple exist" do
      user = user_fixture()
      company = company_fixture(user)

      older_processing = template_fixture(company, %{name: "older.docx", status: :processing})

      older_processing
      |> Ecto.Changeset.change(inserted_at: ~U[2023-01-01 10:00:00Z])
      |> Repo.update!()

      newer_processing = template_fixture(company, %{name: "newer.docx", status: :processing})

      current = CompanyTemplates.get_current_template(company.id)
      assert current.id == newer_processing.id
      assert current.name == "newer.docx"
    end
  end

  describe "get_template/1" do
    test "returns template with preloaded associations" do
      user = user_fixture()
      company = company_fixture(user)
      template = template_fixture(company, %{name: "test.docx", status: :active})

      found_template = CompanyTemplates.get_template(template.id)

      assert found_template.id == template.id
      assert found_template.name == "test.docx"
      assert found_template.status == :active
      assert found_template.company.id == company.id
      assert Map.has_key?(found_template, :media_asset)
    end

    test "returns nil for non-existent template" do
      non_existent_id = Ecto.UUID.generate()
      refute CompanyTemplates.get_template(non_existent_id)
    end
  end

  describe "update_template/2" do
    test "updates template with valid attributes" do
      user = user_fixture()
      company = company_fixture(user)
      template = template_fixture(company, %{status: :uploading})

      attrs = %{
        error_message: nil,
        status: :active,
        variables: ["name", "position"]
      }

      assert {:ok, updated_template} = CompanyTemplates.update_template(template, attrs)
      assert updated_template.status == :active
      assert updated_template.variables == ["name", "position"]
      assert updated_template.error_message == nil
    end

    test "returns error with invalid attributes" do
      user = user_fixture()
      company = company_fixture(user)
      template = template_fixture(company)

      attrs = %{status: :invalid_status}

      assert {:error, %Ecto.Changeset{}} = CompanyTemplates.update_template(template, attrs)
    end

    test "updates error message on failed status" do
      user = user_fixture()
      company = company_fixture(user)
      template = template_fixture(company, %{status: :processing})

      attrs = %{
        error_message: "Processing failed due to invalid format",
        status: :failed
      }

      assert {:ok, updated_template} = CompanyTemplates.update_template(template, attrs)
      assert updated_template.status == :failed
      assert updated_template.error_message == "Processing failed due to invalid format"
    end
  end

  describe "activate_template/1" do
    test "activates template and deactivates existing active template" do
      user = user_fixture()
      company = company_fixture(user)

      active_template = template_fixture(company, %{name: "active.docx", status: :active})
      inactive_template = template_fixture(company, %{name: "inactive.docx", status: :inactive})

      assert {:ok, activated_template} = CompanyTemplates.activate_template(inactive_template.id)
      assert activated_template.id == inactive_template.id
      assert activated_template.status == :active

      updated_active_template = Repo.get(CompanyTemplate, active_template.id)
      assert updated_active_template.status == :uploading

      query =
        from(t in CompanyTemplate, where: t.company_id == ^company.id and t.status == :active)

      assert Repo.aggregate(query, :count) == 1
    end

    test "activates template when no existing active template" do
      user = user_fixture()
      company = company_fixture(user)

      inactive_template = template_fixture(company, %{name: "inactive.docx", status: :inactive})

      assert {:ok, activated_template} = CompanyTemplates.activate_template(inactive_template.id)

      assert activated_template.id == inactive_template.id
      assert activated_template.status == :active
    end

    test "returns error for non-existent template" do
      non_existent_id = Ecto.UUID.generate()

      assert {:error, :not_found} = CompanyTemplates.activate_template(non_existent_id)
    end
  end
end
