defmodule BemedaPersonal.CompanyTemplates do
  @moduledoc """
  The CompanyTemplates context.

  Manages job offer templates for companies, including upload and basic management.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.CompanyTemplates.CompanyTemplate
  alias BemedaPersonal.Repo

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type company :: Company.t()
  @type company_id :: Ecto.UUID.t()
  @type template :: CompanyTemplate.t()
  @type template_id :: Ecto.UUID.t()

  @doc """
  Creates a company template.

  ## Examples

      iex> create_template(company, %{name: "template.docx"})
      {:ok, %CompanyTemplate{}}

      iex> create_template(company, %{})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_template(company(), attrs()) :: {:ok, template()} | {:error, changeset()}
  def create_template(%Company{} = company, attrs) do
    %CompanyTemplate{}
    |> CompanyTemplate.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:company, company)
    |> Repo.insert()
  end

  @doc """
  Gets the active template for a company.

  Returns nil if no active template exists.

  ## Examples

      iex> get_active_template("company-id")
      %CompanyTemplate{}

      iex> get_active_template("company-without-template")
      nil

  """
  @spec get_active_template(company_id()) :: template() | nil
  def get_active_template(company_id) do
    query =
      from t in CompanyTemplate,
        where: t.company_id == ^company_id and t.status == :active,
        order_by: [desc: t.inserted_at],
        limit: 1,
        preload: [:media_asset]

    Repo.one(query)
  end

  @doc """
  Creates a new active template, replacing any existing active template.

  This function deactivates any existing active template first, then creates the new one.
  Uses Ecto.Multi to ensure data integrity.

  ## Examples

      iex> replace_active_template(company, %{name: "new_template.docx"})
      {:ok, %CompanyTemplate{}}

      iex> replace_active_template(company, %{})
      {:error, %Ecto.Changeset{}}

  """
  @spec replace_active_template(company(), attrs()) :: {:ok, template()} | {:error, changeset()}
  def replace_active_template(%Company{} = company, attrs) do
    multi =
      Ecto.Multi.new()
      |> maybe_deactivate_existing_template(company.id)
      |> Ecto.Multi.run(:new_template, fn _repo, _changes ->
        active_attrs = Map.put(attrs, :status, :active)
        create_template(company, active_attrs)
      end)

    case Repo.transaction(multi) do
      {:ok, %{new_template: template}} -> {:ok, template}
      {:error, _operation, changeset, _changes} -> {:error, changeset}
    end
  end

  defp maybe_deactivate_existing_template(multi, company_id) do
    case get_active_template(company_id) do
      nil ->
        multi

      existing_template ->
        Ecto.Multi.run(multi, :deactivate_existing, fn _repo, _changes ->
          existing_template
          |> CompanyTemplate.changeset(%{status: :inactive})
          |> Repo.update()
        end)
    end
  end

  @doc """
  Deletes a company template.

  ## Examples

      iex> delete_template(template)
      {:ok, %CompanyTemplate{}}

      iex> delete_template(template)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_template(template()) :: {:ok, template()} | {:error, changeset()}
  def delete_template(%CompanyTemplate{} = template) do
    Repo.delete(template, allow_stale: true)
  end
end
