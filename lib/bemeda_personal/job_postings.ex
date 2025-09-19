defmodule BemedaPersonal.JobPostings do
  @moduledoc """
  The JobPostings context - interface for job posting operations.
  """

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.JobPostings.JobPosting
  alias BemedaPersonal.JobPostings.JobPostings

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type company :: Company.t()
  @type company_id :: String.t()
  @type job_posting :: JobPosting.t()
  @type job_posting_id :: Ecto.UUID.t()
  @type scope :: Scope.t()

  # Note: list_job_postings/2 has been removed - use scoped versions only
  defdelegate change_job_posting(job_posting, attrs \\ %{}),
    to: BemedaPersonal.JobPostings.JobPostings

  # Functions with explicit implementations to handle different argument types
  @spec get_job_posting!(scope(), job_posting_id()) :: job_posting()
  def get_job_posting!(%Scope{} = scope, id),
    do: JobPostings.get_job_posting!(scope, id)

  # Nil scope version - allows public viewing of job postings
  @spec get_job_posting!(nil, job_posting_id()) :: job_posting()
  def get_job_posting!(nil, id) do
    # Public access - allow viewing any job posting
    JobPosting
    |> BemedaPersonal.Repo.get!(id)
    |> BemedaPersonal.Repo.preload([:media_asset, company: :media_asset])
  end

  @spec create_job_posting(scope() | nil, attrs()) ::
          {:ok, job_posting()} | {:error, changeset() | :unauthorized}
  def create_job_posting(%Scope{} = scope, attrs),
    do: JobPostings.create_job_posting(scope, attrs)

  # Nil scope version - returns unauthorized for nil scope (no access)
  def create_job_posting(nil, _attrs), do: {:error, :unauthorized}

  @spec update_job_posting(scope() | nil, job_posting(), attrs()) ::
          {:ok, job_posting()} | {:error, changeset() | :unauthorized}
  def update_job_posting(%Scope{} = scope, job_posting, attrs),
    do: JobPostings.update_job_posting(scope, job_posting, attrs)

  # Nil scope version - returns unauthorized for nil scope (no access)
  def update_job_posting(nil, _job_posting, _attrs), do: {:error, :unauthorized}

  @spec delete_job_posting(scope() | nil, job_posting()) ::
          {:ok, job_posting()} | {:error, changeset() | :unauthorized}
  def delete_job_posting(%Scope{} = scope, job_posting),
    do: JobPostings.delete_job_posting(scope, job_posting)

  # Nil scope version - returns unauthorized for nil scope (no access)
  def delete_job_posting(nil, _job_posting), do: {:error, :unauthorized}

  @spec company_jobs_count(scope(), company_id()) :: non_neg_integer()
  def company_jobs_count(%Scope{} = scope, company_id),
    do: JobPostings.company_jobs_count(scope, company_id)

  # Functions that need explicit implementation due to conflicting arities
  @spec count_job_postings(map() | scope() | nil) :: non_neg_integer()
  def count_job_postings(filters \\ %{})

  def count_job_postings(filters) when is_map(filters),
    do: JobPostings.count_job_postings(filters)

  # Scope-based version
  def count_job_postings(%Scope{} = scope),
    do: JobPostings.count_job_postings(scope)

  # Nil scope version - returns 0 for nil scope (no access)
  def count_job_postings(nil), do: 0

  @spec list_job_postings(scope() | nil | map()) :: [job_posting()]

  # Scope-based version - must come before general map pattern
  def list_job_postings(%Scope{} = scope),
    do: JobPostings.list_job_postings(scope)

  # Legacy test support - map filters
  def list_job_postings(filters) when is_map(filters),
    do: JobPostings.list_job_postings(filters)

  # Nil scope version - returns empty list for nil scope (no access)
  def list_job_postings(nil), do: []

  @doc """
  Returns all job postings using system scope - for testing purposes.
  """
  @spec list_job_postings() :: [job_posting()]
  def list_job_postings do
    JobPostings.list_job_postings(Scope.system())
  end

  @doc """
  Legacy test support: list_job_postings with filters and limit.
  """
  @spec list_job_postings(map(), integer()) :: [job_posting()]
  def list_job_postings(filters, limit) when is_map(filters) and is_integer(limit),
    do: JobPostings.list_job_postings(filters, limit)

  @doc """
  Legacy test support: get_job_posting!/1 using system scope.
  """
  @spec get_job_posting!(job_posting_id()) :: job_posting()
  def get_job_posting!(id),
    do: get_job_posting!(Scope.system(), id)

  @doc """
  Legacy test support: update_job_posting/2 using system scope.
  """
  @spec update_job_posting(job_posting(), attrs()) :: {:ok, job_posting()} | {:error, changeset()}
  def update_job_posting(job_posting, attrs),
    do: update_job_posting(Scope.system(), job_posting, attrs)

  @doc """
  Legacy test support: delete_job_posting/1 using system scope.
  """
  @spec delete_job_posting(job_posting()) :: {:ok, job_posting()} | {:error, changeset()}
  def delete_job_posting(job_posting),
    do: delete_job_posting(Scope.system(), job_posting)

  @doc """
  Legacy test support: company_jobs_count/1 using system scope.
  """
  @spec company_jobs_count(company_id()) :: non_neg_integer()
  def company_jobs_count(company_id),
    do: company_jobs_count(Scope.system(), company_id)
end
