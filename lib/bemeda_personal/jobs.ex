defmodule BemedaPersonal.Jobs do
  @moduledoc """
  The Jobs context.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.Jobs.JobPosting
  alias BemedaPersonal.Repo
  alias Ecto.Changeset
  alias Phoenix.PubSub

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type company :: Company.t()
  @type job_posting :: JobPosting.t()
  @type job_posting_id :: Ecto.UUID.t()

  @job_posting_topic "job_posting"

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

      iex> list_job_postings(%{newer_than: job_posting})
      [%JobPosting{}, ...]

      iex> list_job_postings(%{older_than: job_posting})
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

  defp apply_filter({:newer_than, %JobPosting{} = job_posting}, dynamic) do
    dynamic([job_posting: j], ^dynamic and j.inserted_at > ^job_posting.inserted_at)
  end

  defp apply_filter({:older_than, %JobPosting{} = job_posting}, dynamic) do
    dynamic([job_posting: j], ^dynamic and j.inserted_at < ^job_posting.inserted_at)
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

      iex> create_job_posting(company, %{field: value})
      {:ok, %JobPosting{}}

      iex> create_job_posting(company, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_job_posting(company(), attrs()) ::
          {:ok, job_posting()} | {:error, changeset()}
  def create_job_posting(%Company{} = company, attrs \\ %{}) do
    result =
      %JobPosting{}
      |> JobPosting.changeset(attrs)
      |> Changeset.put_assoc(:company, company)
      |> Repo.insert()

    case result do
      {:ok, job_posting} ->
        broadcast_event(
          "#{@job_posting_topic}:company:#{company.id}",
          {:job_posting_updated, job_posting}
        )

        {:ok, job_posting}

      error ->
        error
    end
  end

  @doc """
  Updates a job_posting.

  ## Examples

      iex> update_job_posting(job_posting, %{field: new_value})
      {:ok, %JobPosting{}}

      iex> update_job_posting(job_posting, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_job_posting(job_posting(), attrs()) ::
          {:ok, job_posting()} | {:error, changeset()}
  def update_job_posting(%JobPosting{} = job_posting, attrs \\ %{}) do
    result =
      job_posting
      |> JobPosting.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated_job_posting} ->
        broadcast_event(
          "#{@job_posting_topic}:company:#{job_posting.company.id}",
          {:job_posting_updated, updated_job_posting}
        )

        {:ok, updated_job_posting}

      error ->
        error
    end
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
    # Preload company to get the company_id for scoping the topic
    job_posting = Repo.preload(job_posting, :company)
    result = Repo.delete(job_posting)

    case result do
      {:ok, deleted_job_posting} ->
        broadcast_event(
          "#{@job_posting_topic}:company:#{deleted_job_posting.company.id}",
          {:job_posting_deleted, deleted_job_posting}
        )

        {:ok, deleted_job_posting}

      error ->
        error
    end
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

  @doc """
  Returns the count of job postings for a specific company.

  ## Examples

      iex> company_jobs_count(company_id)
      5

  """
  @spec company_jobs_count(Ecto.UUID.t()) :: non_neg_integer()
  def company_jobs_count(company_id) do
    job_posting_query()
    |> where([j], j.company_id == ^company_id)
    |> select([j], count(j.id))
    |> Repo.one()
  end

  defp broadcast_event(topic, message) do
    PubSub.broadcast(
      BemedaPersonal.PubSub,
      topic,
      message
    )
  end
end
