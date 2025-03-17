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

      iex> list_job_postings(%{company_id: company_id})
      [%JobPosting{}, ...]

      iex> list_job_postings(%{salary_range: [50000, 100_000]})
      [%JobPosting{}, ...]

      iex> list_job_postings(%{title: "Engineer", remote_allowed: true})
      [%JobPosting{}, ...]

  """
  @spec list_job_postings(map(), non_neg_integer()) :: [job_posting()]
  def list_job_postings(filters \\ %{}, limit \\ 10) do
    filter_query = apply_filters()

    job_posting_query()
    |> where(^filter_query.(filters))
    |> order_by([j], desc: j.inserted_at)
    |> limit(^limit)
    |> Repo.all()
    |> Repo.preload(:company)
  end

  defp job_posting_query do
    from job_posting in JobPosting, as: :job_posting
  end

  defp apply_filters do
    fn filters ->
      Enum.reduce(filters, dynamic(true), &apply_filter/2)
    end
  end

  defp apply_filter({:company_id, company_id}, dynamic) do
    dynamic([job_posting: j], ^dynamic and j.company_id == ^company_id)
  end

  defp apply_filter({:title, title}, dynamic) do
    pattern = "%#{title}%"
    dynamic([job_posting: j], ^dynamic and ilike(j.title, ^pattern))
  end

  defp apply_filter({:employment_type, employment_type}, dynamic) do
    pattern = "%#{employment_type}%"
    dynamic([job_posting: j], ^dynamic and ilike(j.employment_type, ^pattern))
  end

  defp apply_filter({:experience_level, experience_level}, dynamic) do
    pattern = "%#{experience_level}%"
    dynamic([job_posting: j], ^dynamic and ilike(j.experience_level, ^pattern))
  end

  defp apply_filter({:remote_allowed, remote_allowed}, dynamic) do
    dynamic([job_posting: j], ^dynamic and j.remote_allowed == ^remote_allowed)
  end

  defp apply_filter({:location, location}, dynamic) do
    pattern = "%#{location}%"
    dynamic([job_posting: j], ^dynamic and ilike(j.location, ^pattern))
  end

  defp apply_filter({:salary_range, [min, max]}, dynamic) do
    dynamic([job_posting: j], ^dynamic and j.salary_min <= ^max and j.salary_max >= ^min)
  end

  defp apply_filter(_other, dynamic), do: dynamic

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
