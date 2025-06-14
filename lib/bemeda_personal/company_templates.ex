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
  Gets the current template for a company, prioritizing processing templates over active ones.

  This is useful for UI display where we want to show a processing template immediately
  rather than falling back to the old active template.

  Returns the most recent processing template, or the active template if no processing template exists.

  ## Examples

      iex> get_current_template("company-id")
      %CompanyTemplate{status: :processing}

      iex> get_current_template("company-without-templates")
      nil

  """
  @spec get_current_template(company_id()) :: template() | nil
  def get_current_template(company_id) do
    processing_query =
      from t in CompanyTemplate,
        where: t.company_id == ^company_id and t.status == :processing,
        order_by: [desc: t.inserted_at],
        limit: 1,
        preload: [:media_asset]

    case Repo.one(processing_query) do
      %CompanyTemplate{} = processing_template ->
        processing_template

      nil ->
        get_active_template(company_id)
    end
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
    final_attrs = Map.put_new(attrs, :status, :active)
    should_deactivate_existing = final_attrs.status == :active

    multi =
      Ecto.Multi.new()
      |> maybe_deactivate_existing_template_if(company.id, should_deactivate_existing)
      |> Ecto.Multi.run(:new_template, fn _repo, _changes ->
        create_template(company, final_attrs)
      end)

    case Repo.transaction(multi) do
      {:ok, %{new_template: template}} -> {:ok, template}
      {:error, _operation, changeset, _changes} -> {:error, changeset}
    end
  end

  defp maybe_deactivate_existing_template(multi, company_id) do
    maybe_deactivate_existing_template_if(multi, company_id, true)
  end

  defp maybe_deactivate_existing_template_if(multi, company_id, should_deactivate) do
    cond do
      not should_deactivate ->
        multi

      is_nil(get_active_template(company_id)) ->
        multi

      true ->
        existing_template = get_active_template(company_id)

        Ecto.Multi.run(multi, :deactivate_existing, fn _repo, _changes ->
          update_template(existing_template, %{status: :uploading})
        end)
    end
  end

  @doc """
  Archives a company template by setting its status to :inactive.

  This preserves the template data while making it inactive.

  ## Examples

      iex> archive_template(template)
      {:ok, %CompanyTemplate{}}

      iex> archive_template(template)
      {:error, %Ecto.Changeset{}}

  """
  @spec archive_template(template()) :: {:ok, template()} | {:error, changeset()}
  def archive_template(%CompanyTemplate{} = template) do
    update_template(template, %{status: :inactive})
  end

  @doc """
  Gets a template by ID with preloaded associations.

  ## Examples

      iex> get_template("template-id")
      %CompanyTemplate{}

      iex> get_template("non-existent-id")
      nil

  """
  @spec get_template(template_id()) :: template() | nil
  def get_template(template_id) do
    case Repo.get(CompanyTemplate, template_id) do
      %CompanyTemplate{} = template ->
        Repo.preload(template, [:company, :media_asset])

      nil ->
        nil
    end
  end

  @doc """
  Updates template processing status and related fields.

  ## Examples

      iex> update_template(template, %{status: :active, variables: ["var1"]})
      {:ok, %CompanyTemplate{}}

      iex> update_template(template, %{status: :unknown})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_template(template(), attrs()) :: {:ok, template()} | {:error, changeset()}
  def update_template(template, attrs) do
    template
    |> CompanyTemplate.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Activates a template, deactivating any other active templates for the same company.

  ## Examples

      iex> activate_template("template-id")
      {:ok, %CompanyTemplate{}}

      iex> activate_template("invalid-id")
      {:error, :not_found}

  """
  @spec activate_template(template_id()) :: {:ok, template()} | {:error, changeset() | :not_found}
  def activate_template(template_id) do
    case get_template(template_id) do
      nil ->
        {:error, :not_found}

      %CompanyTemplate{} = template ->
        multi =
          Ecto.Multi.new()
          |> maybe_deactivate_existing_template(template.company_id)
          |> Ecto.Multi.run(:activate_template, fn _repo, _changes ->
            update_template(template, %{status: :active})
          end)

        case Repo.transaction(multi) do
          {:ok, %{activate_template: activated_template}} -> {:ok, activated_template}
          {:error, _operation, changeset, _changes} -> {:error, changeset}
        end
    end
  end
end
