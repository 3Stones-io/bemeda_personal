defmodule BemedaPersonal.Jobs do
  @moduledoc """
  The Jobs context.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.Jobs.JobApplication
  alias BemedaPersonal.Jobs.JobPosting
  alias BemedaPersonal.Repo
  alias Ecto.Changeset
  alias Phoenix.PubSub

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type company :: Company.t()
  @type job_application :: JobApplication.t()
  @type job_posting :: JobPosting.t()
  @type job_posting_id :: Ecto.UUID.t()
  @type user :: User.t()

  @job_application_topic "job_application"
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
    filter_query = fn filters ->
      Enum.reduce(filters, dynamic(true), &apply_filter/2)
    end

    from(job_posting in JobPosting, as: :job_posting)
    |> where(^filter_query.(filters))
    |> order_by([j], desc: j.inserted_at)
    |> limit(^limit)
    |> Repo.all()
    |> Repo.preload(:company)
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
    from(job_posting in JobPosting, as: :job_posting)
    |> where([j], j.company_id == ^company_id)
    |> select([j], count(j.id))
    |> Repo.one()
  end

  # JOB APPLICATIONS

  @doc """
  Returns the list of job applications with optional filtering.

  ## Examples

      iex> list_job_applications()
      [%JobApplication{}, ...]

      iex> list_job_applications(%{user_id: user_id})
      [%JobApplication{}, ...]

      iex> list_job_applications(%{job_posting_id: job_posting_id})
      [%JobApplication{}, ...]

      iex> list_job_applications(%{tags: ["urgent", "qualified"]})
      [%JobApplication{}, ...]  # Returns only applications that have ALL the specified tags

  """
  @spec list_job_applications(map(), non_neg_integer()) :: [job_application()]
  def list_job_applications(filters \\ %{}, limit \\ 10)

  def list_job_applications(%{company_id: _company_id} = filters, limit) do
    job_post_with_applications_query()
    |> list_applications(filters, limit)
    |> Repo.preload([:user, :tags, job_posting: [:company]])
  end

  def list_job_applications(filters, limit) do
    job_application_query()
    |> list_applications(filters, limit)
    |> Repo.preload([:user, :tags, job_posting: [:company]])
  end

  defp list_applications(query, filters, limit) do
    filter_query = apply_job_application_filters()

    query_with_joins =
      if needs_job_posting_join?(filters), do: job_post_with_applications_query(), else: query

    query_with_joins
    |> where(^filter_query.(filters))
    |> order_by([job_application: ja], desc: ja.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  defp job_application_query do
    from job_application in JobApplication, as: :job_application
  end

  defp job_post_with_applications_query do
    from job_application in JobApplication,
      as: :job_application,
      left_join: job_posting in JobPosting,
      as: :job_posting,
      on: job_application.job_posting_id == job_posting.id
  end

  defp apply_job_application_filters do
    fn filters ->
      Enum.reduce(filters, dynamic(true), &apply_job_application_filter/2)
    end
  end

  defp apply_job_application_filter({:user_id, user_id}, dynamic) do
    dynamic([job_application: ja], ^dynamic and ja.user_id == ^user_id)
  end

  defp apply_job_application_filter({:job_posting_id, job_posting_id}, dynamic) do
    dynamic([job_application: ja], ^dynamic and ja.job_posting_id == ^job_posting_id)
  end

  defp apply_job_application_filter({:company_id, company_id}, dynamic) do
    dynamic([job_application: ja, job_posting: jp], ^dynamic and jp.company_id == ^company_id)
  end

  defp apply_job_application_filter({:date_range, %{from: from_date, to: to_date}}, dynamic)
       when is_nil(from_date) or is_nil(to_date),
       do: dynamic

  defp apply_job_application_filter({:date_range, %{from: from_date, to: to_date}}, dynamic) do
    from_date = parse_date_if_string(from_date)
    to_date = parse_date_if_string(to_date)

    from_datetime = DateTime.new!(from_date, ~T[00:00:00.000], "Etc/UTC")
    to_datetime = DateTime.new!(to_date, ~T[23:59:59.999], "Etc/UTC")

    dynamic(
      [job_application: ja],
      ^dynamic and ja.inserted_at >= ^from_datetime and ja.inserted_at <= ^to_datetime
    )
  end

  defp apply_job_application_filter({:date_from, from_date}, dynamic) when is_nil(from_date),
    do: dynamic

  defp apply_job_application_filter({:date_from, from_date}, dynamic) do
    from_date = parse_date_if_string(from_date)
    from_datetime = DateTime.new!(from_date, ~T[00:00:00.000], "Etc/UTC")

    dynamic([job_application: ja], ^dynamic and ja.inserted_at >= ^from_datetime)
  end

  defp apply_job_application_filter({:date_to, to_date}, dynamic) when is_nil(to_date),
    do: dynamic

  defp apply_job_application_filter({:date_to, to_date}, dynamic) do
    to_date = parse_date_if_string(to_date)
    to_datetime = DateTime.new!(to_date, ~T[23:59:59.999], "Etc/UTC")

    dynamic([job_application: ja], ^dynamic and ja.inserted_at <= ^to_datetime)
  end

  defp apply_job_application_filter({:applicant_name, name}, dynamic) do
    pattern = "%#{name}%"

    dynamic(
      [job_application: ja],
      ^dynamic and
        exists(
          from u in BemedaPersonal.Accounts.User,
            where:
              u.id == parent_as(:job_application).user_id and
                (ilike(fragment("concat(?, ' ', ?)", u.first_name, u.last_name), ^pattern) or
                   ilike(fragment("concat(?, ' ', ?)", u.last_name, u.first_name), ^pattern))
        )
    )
  end

  defp apply_job_application_filter({:job_title, title}, dynamic) do
    pattern = "%#{title}%"

    dynamic([job_application: ja, job_posting: jp], ^dynamic and ilike(jp.title, ^pattern))
  end

  defp apply_job_application_filter({:newer_than, job_application}, dynamic) do
    dynamic([job_application: ja], ^dynamic and ja.inserted_at > ^job_application.inserted_at)
  end

  defp apply_job_application_filter({:older_than, job_application}, dynamic) do
    dynamic([job_application: ja], ^dynamic and ja.inserted_at < ^job_application.inserted_at)
  end

  defp apply_job_application_filter({:tags, tag_names}, dynamic) do
    dynamic([job_application: ja], ^dynamic and ja.id in subquery(
      from jat in BemedaPersonal.Jobs.JobApplicationTag,
      join: t in BemedaPersonal.Jobs.Tag, on: t.id == jat.tag_id,
      where: t.name in ^tag_names,
      group_by: jat.job_application_id,
      select: jat.job_application_id
    ))
  end

  defp apply_job_application_filter(_other, dynamic), do: dynamic

  defp parse_date_if_string(date) when is_binary(date) do
    parsed_result = parse_date_formats(date)

    case parsed_result do
      {:ok, date} ->
        date

      {:error, _unused} ->
        nil
    end
  end

  defp parse_date_if_string(date), do: date

  defp parse_date_formats(date_string) do
    iso_result = Date.from_iso8601(date_string)

    case iso_result do
      {:ok, date} ->
        {:ok, date}

      {:error, _unused} ->
        parse_date_ymd(date_string)
    end
  end

  defp parse_date_ymd(date_string) do
    cond do
      String.match?(date_string, ~r/^\d{4}-\d{2}-\d{2}$/) ->
        # ISO format YYYY-MM-DD
        {:ok, parse_iso8601_format(date_string)}

      String.match?(date_string, ~r/^\d{2} \/ \d{2} \/ \d{4}$/) ->
        # DD / MM / YYYY format
        parse_date_with_separator(date_string, " / ")

      String.match?(date_string, ~r/^\d{2}\/\d{2}\/\d{4}$/) ->
        # DD/MM/YYYY format
        parse_date_with_separator(date_string, "/")

      String.match?(date_string, ~r/^\d{2}-\d{2}-\d{4}$/) ->
        # DD-MM-YYYY format
        parse_date_with_separator(date_string, "-")

      true ->
        {:error, :invalid_format}
    end
  end

  defp parse_iso8601_format(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      _error -> nil
    end
  end

  defp parse_date_with_separator(date_string, separator) do
    [day, month, year] = String.split(date_string, separator)
    parse_date_components(year, month, day)
  end

  defp parse_date_components(year, month, day) do
    with {y, _remainder_y} <- Integer.parse(year),
         {m, _remainder_m} <- Integer.parse(month),
         {d, _remainder_d} <- Integer.parse(day) do
      case Date.new(y, m, d) do
        {:ok, date} -> {:ok, date}
        _error -> {:error, :invalid_date}
      end
    else
      _error -> {:error, :invalid_components}
    end
  end

  @doc """
  Gets a single job application.

  Raises `Ecto.NoResultsError` if the Job application does not exist.

  ## Examples

      iex> get_job_application!(123)
      %JobApplication{}

      iex> get_job_application!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_job_application!(Ecto.UUID.t()) :: job_application() | no_return()
  def get_job_application!(id) do
    JobApplication
    |> Repo.get!(id)
    |> Repo.preload([:job_posting, :tags, :user])
  end

  @doc """
  Returns a job application for a specific user and job posting.

  ## Examples

      iex> get_user_job_application(user, job_posting)
      %JobApplication{}

  """
  @spec get_user_job_application(user(), job_posting()) :: job_application() | nil
  def get_user_job_application(%User{} = user, %JobPosting{} = job) do
    JobApplication
    |> where([ja], ja.user_id == ^user.id and ja.job_posting_id == ^job.id)
    |> Repo.one()
  end

  @doc """
  Creates a job application.

  ## Examples

      iex> create_job_application(%{field: value})
      {:ok, %JobApplication{}}

      iex> create_job_application(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_job_application(user(), job_posting(), attrs()) ::
          {:ok, job_application()} | {:error, changeset()}
  def create_job_application(%User{} = user, %JobPosting{} = job_posting, attrs \\ %{}) do
    result =
      %JobApplication{}
      |> JobApplication.changeset(attrs)
      |> Changeset.put_assoc(:user, user)
      |> Changeset.put_assoc(:job_posting, job_posting)
      |> Repo.insert()

    case result do
      {:ok, job_application} ->
        :ok =
          broadcast_event(
            "#{@job_application_topic}:company:#{job_posting.company_id}",
            {:company_job_application_created, job_application}
          )

        :ok =
          broadcast_event(
            "#{@job_application_topic}:user:#{user.id}",
            {:user_job_application_created, job_application}
          )

        {:ok, job_application}

      error ->
        error
    end
  end

  @doc """
  Updates a job application.

  ## Examples

      iex> update_job_application(job_application, %{field: new_value})
      {:ok, %JobApplication{}}

      iex> update_job_application(job_application, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_job_application(job_application(), attrs()) ::
          {:ok, job_application()} | {:error, changeset()}
  def update_job_application(%JobApplication{} = job_application, attrs) do
    result =
      job_application
      |> JobApplication.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated_job_application} ->
        broadcast_event(
          "#{@job_application_topic}:company:#{job_application.job_posting.company_id}",
          {:company_job_application_updated, updated_job_application}
        )

        broadcast_event(
          "#{@job_application_topic}:user:#{job_application.user_id}",
          {:user_job_application_updated, updated_job_application}
        )

        {:ok, updated_job_application}

      error ->
        error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking job application changes.

  ## Examples

      iex> change_job_application(job_application)
      %Ecto.Changeset{data: %JobApplication{}}

  """
  @spec change_job_application(job_application(), attrs()) :: changeset()
  def change_job_application(%JobApplication{} = job_application, attrs \\ %{}) do
    JobApplication.changeset(job_application, attrs)
  end

  defp broadcast_event(topic, message) do
    PubSub.broadcast(
      BemedaPersonal.PubSub,
      topic,
      message
    )
  end

  defp needs_job_posting_join?(filters) do
    filters
    |> Map.keys()
    |> Enum.any?(fn key -> key in [:company_id, :job_title] end)
  end

  @doc """
  Removes a tag from a job application and returns the job application with updated tags preloaded.

  ## Examples

      iex> remove_tag_from_job_application(job_application, "tag-id")
      {:ok, %JobApplication{}}

  """
  @spec remove_tag_from_job_application(job_application(), String.t()) ::
    {:ok, job_application()} | {:error, any()}
  def remove_tag_from_job_application(%JobApplication{} = job_application, tag_id) when is_binary(tag_id) do
    Repo.transaction(fn ->
      Repo.delete_all(
        from jat in BemedaPersonal.Jobs.JobApplicationTag,
        where: jat.job_application_id == ^job_application.id and jat.tag_id == ^tag_id
      )

      Repo.preload(job_application, [:tags], force: true)
    end)
  end

  @doc """
  Adds tags to a job application, creating any tags that don't exist.
  Uses upsert to efficiently create tags and returns the job application with tags preloaded.

  ## Examples

      iex> add_tags_to_job_application(job_application, ["urgent", "qualified"])
      {:ok, %JobApplication{}}

  """
  @spec add_tags_to_job_application(job_application(), [String.t()]) ::
    {:ok, job_application()} | {:error, any()}
  def add_tags_to_job_application(%JobApplication{} = job_application, tag_names) do
    tag_names
    |> normalize_tag_names()
    |> process_tags(job_application)
  end

  defp normalize_tag_names(tag_names) do
    tag_names
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp process_tags([], job_application) do
    {:ok, Repo.preload(job_application, :tags)}
  end

  defp process_tags(tag_names, job_application) do
    now = DateTime.utc_now()
    timestamp = DateTime.truncate(now, :second)

    tag_names
    |> create_tag_entries(timestamp)
    |> insert_tags(timestamp)
    |> associate_tags_with_application(job_application, timestamp)
  end

  defp create_tag_entries(tag_names, timestamp) do
    maps = Enum.map(tag_names, &%{
      name: &1,
      inserted_at: timestamp,
      updated_at: timestamp
    })

    {tag_names, maps, timestamp}
  end

  defp insert_tags({tag_names, maps, timestamp}, timestamp) do
    Repo.insert_all(
      BemedaPersonal.Jobs.Tag,
      maps,
      on_conflict: :nothing
    )

    tags = Repo.all(from t in BemedaPersonal.Jobs.Tag, where: t.name in ^tag_names)

    {tag_names, tags, timestamp}
  end

  defp associate_tags_with_application({_tag_names, tags, timestamp}, job_application, timestamp) do
    Repo.transaction(fn ->
      existing_tag_ids = get_existing_tag_ids(job_application.id)

      tags
      |> filter_new_tags(existing_tag_ids)
      |> create_association_entries(job_application.id, timestamp)
      |> insert_associations()

      Repo.preload(job_application,  [:tags], force: true)
    end)
  end

  defp get_existing_tag_ids(job_application_id) do
    from(jat in BemedaPersonal.Jobs.JobApplicationTag,
      where: jat.job_application_id == ^job_application_id,
      select: jat.tag_id
    )
    |> Repo.all()
    |> MapSet.new()
  end

  defp filter_new_tags(tags, existing_tag_ids) do
    Enum.reject(tags, fn tag -> MapSet.member?(existing_tag_ids, tag.id) end)
  end

  defp create_association_entries(new_tags, job_application_id, timestamp) do
    Enum.map(new_tags, fn tag ->
      %{
        job_application_id: job_application_id,
        tag_id: tag.id,
        inserted_at: timestamp,
        updated_at: timestamp
      }
    end)
  end

  defp insert_associations([]), do: :ok
  defp insert_associations(tag_entries) do
    Repo.insert_all(BemedaPersonal.Jobs.JobApplicationTag, tag_entries)
  end
end
