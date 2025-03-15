defmodule BemedaPersonal.Jobs do
  @moduledoc """
  The Jobs context.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.Jobs.JobPosting
  alias BemedaPersonal.Repo
  alias Ecto.Changeset

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type company :: Company.t()
  @type job_posting :: JobPosting.t()
  @type job_posting_id :: Ecto.UUID.t()

  @doc """
  Returns the list of job_postings.

  ## Examples

      iex> list_job_postings()
      [%JobPosting{}, ...]

  """
  @spec list_job_postings() :: [job_posting()]
  def list_job_postings do
    JobPosting
    |> order_by([j], desc: j.inserted_at)
    |> Repo.all()
    |> Repo.preload(:company)
  end

  @doc """
  Returns the list of job_postings for a specific company.

  ## Examples

      iex> list_company_job_postings(company_id)
      [%JobPosting{}, ...]

  """
  @spec list_company_job_postings(company()) :: [job_posting()]
  def list_company_job_postings(%Company{} = company) do
    JobPosting
    |> where([j], j.company_id == ^company.id)
    |> order_by([j], desc: j.inserted_at)
    |> Repo.all()
    |> Repo.preload(:company)
  end

  @doc """
  Gets a single job_posting.

  Raises `Ecto.NoResultsError` if the Job posting does not exist.

  ## Examples

      iex> get_job_posting!(123)
      %JobPosting{}

      iex> get_job_posting!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_job_posting!(job_posting_id()) :: job_posting() | no_return()
  def get_job_posting!(id) do
    JobPosting
    |> Repo.get!(id)
    |> Repo.preload(:company)
  end

  @doc """
  Creates a job_posting.

  ## Examples

      iex> create_or_update_job_posting(company, %{field: value})
      {:ok, %JobPosting{}}

      iex> create_or_update_job_posting(company, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_or_update_job_posting(company(), attrs()) ::
          {:ok, job_posting()} | {:error, changeset()}
  def create_or_update_job_posting(%Company{} = company, attrs \\ %{}) do
    %JobPosting{}
    |> JobPosting.changeset(attrs)
    |> Changeset.put_assoc(:company, company)
    |> Repo.insert_or_update()
  end

  @doc """
  Deletes a job_posting.

  ## Examples

      iex> delete_job_posting(job_posting)
      {:ok, %JobPosting{}}

      iex> delete_job_posting(job_posting)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_job_posting(job_posting()) :: {:ok, job_posting()} | {:error, changeset()}
  def delete_job_posting(job_posting) do
    Repo.delete(job_posting)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking job_posting changes.

  ## Examples

      iex> change_job_posting(job_posting)
      %Ecto.Changeset{data: %JobPosting{}}

  """
  @spec change_job_posting(job_posting(), attrs()) :: changeset()
  def change_job_posting(%JobPosting{} = job_posting, attrs \\ %{}) do
    JobPosting.changeset(job_posting, attrs)
  end
end
