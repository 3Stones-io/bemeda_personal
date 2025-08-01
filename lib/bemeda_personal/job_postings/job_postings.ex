defmodule BemedaPersonal.JobPostings.JobPostings do
  @moduledoc """
  Job postings management functionality.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.JobPostings.JobPosting
  alias BemedaPersonal.JobPostings.JobPostingFilters
  alias BemedaPersonal.MediaDataUtils
  alias BemedaPersonal.QueryBuilder
  alias BemedaPersonal.Repo
  alias BemedaPersonalWeb.Endpoint
  alias Ecto.Changeset
  alias Ecto.Multi

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
    from(job_posting in JobPosting, as: :job_posting)
    |> QueryBuilder.apply_filters(filters, JobPostingFilters.filter_config())
    |> order_by([j], desc: j.inserted_at)
    |> limit(^limit)
    |> Repo.all()
    |> Repo.preload([:media_asset, company: :media_asset])
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
    |> Repo.preload([:media_asset, company: :media_asset])
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
    changeset =
      %JobPosting{}
      |> JobPosting.changeset(attrs)
      |> Changeset.put_assoc(:company, company)

    multi =
      Multi.new()
      |> Multi.insert(:job_posting, changeset)
      |> Multi.run(:media_asset, fn repo, %{job_posting: job_posting} ->
        MediaDataUtils.handle_media_asset(repo, nil, job_posting, attrs)
      end)

    case Repo.transaction(multi) do
      {:ok, %{job_posting: job_posting}} ->
        job_posting =
          Repo.preload(
            job_posting,
            [:company, :media_asset],
            force: true
          )

        broadcast_event(
          "#{@job_posting_topic}:company:#{company.id}",
          "job_posting_created",
          %{job_posting: job_posting}
        )

        broadcast_event(
          "#{@job_posting_topic}",
          "job_posting_created",
          %{job_posting: job_posting}
        )

        {:ok, job_posting}

      {:error, _operation, changeset, _changes} ->
        {:error, changeset}
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
    changeset = JobPosting.changeset(job_posting, attrs)

    multi =
      Multi.new()
      |> Multi.update(:job_posting, changeset)
      |> Multi.run(:media_asset, fn repo, %{job_posting: updated_job_posting} ->
        MediaDataUtils.handle_media_asset(
          repo,
          job_posting.media_asset,
          updated_job_posting,
          attrs
        )
      end)

    case Repo.transaction(multi) do
      {:ok, %{job_posting: updated_job_posting}} ->
        updated_job_posting =
          updated_job_posting
          |> Repo.reload()
          |> Repo.preload([:media_asset, company: :media_asset])

        broadcast_event(
          "#{@job_posting_topic}:company:#{job_posting.company.id}",
          "job_posting_updated",
          %{job_posting: updated_job_posting}
        )

        broadcast_event(
          "#{@job_posting_topic}",
          "job_posting_updated",
          %{job_posting: updated_job_posting}
        )

        {:ok, updated_job_posting}

      {:error, _operation, changeset, _changes} ->
        {:error, changeset}
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
    result = Repo.delete(job_posting)

    case result do
      {:ok, deleted_job_posting} ->
        broadcast_event(
          "#{@job_posting_topic}:company:#{deleted_job_posting.company.id}",
          "job_posting_deleted",
          %{job_posting: deleted_job_posting}
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
    from(job_posting in JobPosting, as: :job_posting)
    |> where([j], j.company_id == ^company_id)
    |> select([j], count(j.id))
    |> Repo.one()
  end

  @doc """
  Returns the count of job postings matching the given filters.

  ## Examples

      iex> count_job_postings()
      10

      iex> count_job_postings(%{company_id: company_id})
      5

      iex> count_job_postings(%{salary_range: [50000, 100_000]})
      3

      iex> count_job_postings(%{title: "Engineer", remote_allowed: true})
      2

  """
  @spec count_job_postings(map()) :: non_neg_integer()
  def count_job_postings(filters \\ %{}) do
    from(job_posting in JobPosting, as: :job_posting)
    |> QueryBuilder.apply_filters(filters, JobPostingFilters.filter_config())
    |> select([j], count(j.id))
    |> Repo.one()
  end

  defp broadcast_event(topic, event, message) do
    Endpoint.broadcast(
      topic,
      event,
      message
    )
  end
end
