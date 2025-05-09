defmodule BemedaPersonal.Jobs do
  @moduledoc """
  The Jobs context.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Chat
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.Jobs.JobApplication
  alias BemedaPersonal.Jobs.JobApplicationStateTransition
  alias BemedaPersonal.Jobs.JobApplicationTag
  alias BemedaPersonal.Jobs.JobPosting
  alias BemedaPersonal.Jobs.Tag
  alias BemedaPersonal.Media
  alias BemedaPersonal.Repo
  alias BemedaPersonalWeb.Endpoint
  alias Ecto.Changeset
  alias Ecto.Multi

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type company :: Company.t()
  @type job_application :: JobApplication.t()
  @type job_application_state_transition :: JobApplicationStateTransition.t()
  @type job_posting :: JobPosting.t()
  @type job_posting_id :: Ecto.UUID.t()
  @type tag_id :: Ecto.UUID.t()
  @type tags :: String.t()
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
    |> Repo.preload([:company, :media_asset])
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
    |> Repo.preload([:company, :media_asset])
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
        handle_media_asset(repo, nil, job_posting, attrs)
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
        handle_media_asset(repo, job_posting.media_asset, updated_job_posting, attrs)
      end)

    case Repo.transaction(multi) do
      {:ok, %{job_posting: updated_job_posting}} ->
        updated_job_posting =
          updated_job_posting
          |> Repo.reload()
          |> Repo.preload([:company, :media_asset])

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

  defp handle_media_asset(repo, existing_media_asset, parent, attrs) do
    media_data = Map.get(attrs, "media_data") || Map.get(attrs, :media_data)

    process_media_data(media_data, repo, existing_media_asset, parent)
  end

  defp process_media_data(nil, _repo, nil, _parent), do: {:ok, nil}

  defp process_media_data(nil, _repo, existing_media_asset, _parent),
    do: {:ok, existing_media_asset}

  defp process_media_data(media_data, _repo, nil, parent) do
    Media.create_media_asset(parent, media_data)
  end

  defp process_media_data(media_data, _repo, existing_media_asset, _parent) do
    Media.update_media_asset(existing_media_asset, media_data)
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
      [%JobApplication{}, ...]

  """
  @spec list_job_applications(map(), non_neg_integer()) :: [job_application()]
  def list_job_applications(filters \\ %{}, limit \\ 10)

  def list_job_applications(%{company_id: _company_id} = filters, limit) do
    job_post_with_applications_query()
    |> list_applications(filters, limit)
    |> Repo.preload([:media_asset, :tags, :user, job_posting: [company: :admin_user]])
  end

  def list_job_applications(filters, limit) do
    job_application_query()
    |> list_applications(filters, limit)
    |> Repo.preload([:media_asset, :tags, :user, job_posting: [company: :admin_user]])
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

  defp apply_job_application_filter({:tags, tags}, dynamic) do
    dynamic(
      [job_application: ja],
      ^dynamic and
        ja.id in subquery(
          from jat in JobApplicationTag,
            join: t in Tag,
            on: t.id == jat.tag_id,
            where: t.name in ^tags,
            group_by: jat.job_application_id,
            select: jat.job_application_id
        )
    )
  end

  defp apply_job_application_filter({:state, state}, dynamic) do
    dynamic([job_application: ja], ^dynamic and ja.state == ^state)
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
    |> Repo.preload([:media_asset, :tags, :user, job_posting: [company: :admin_user]])
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
    |> preload([ja], [:media_asset])
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
    changeset =
      %JobApplication{}
      |> JobApplication.changeset(attrs)
      |> Changeset.put_assoc(:user, user)
      |> Changeset.put_assoc(:job_posting, job_posting)

    multi =
      Multi.new()
      |> Multi.insert(:job_application, changeset)
      |> Multi.run(:media_asset, fn repo, %{job_application: job_application} ->
        handle_media_asset(repo, nil, job_application, attrs)
      end)

    case Repo.transaction(multi) do
      {:ok, %{job_application: job_application}} ->
        job_application =
          Repo.preload(
            job_application,
            [:job_posting, :media_asset, :user]
          )

        :ok =
          broadcast_event(
            "#{@job_application_topic}:company:#{job_posting.company_id}",
            "company_job_application_created",
            %{job_application: job_application}
          )

        :ok =
          broadcast_event(
            "#{@job_application_topic}:user:#{user.id}",
            "user_job_application_created",
            %{job_application: job_application}
          )

        {:ok, job_application}

      {:error, _operation, changeset, _changes} ->
        {:error, changeset}
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
    changeset = JobApplication.changeset(job_application, attrs)

    multi =
      Multi.new()
      |> Multi.update(:job_application, changeset)
      |> Multi.run(:media_asset, fn repo, %{job_application: updated_job_application} ->
        handle_media_asset(repo, job_application.media_asset, updated_job_application, attrs)
      end)

    case Repo.transaction(multi) do
      {:ok, %{job_application: updated_job_application}} ->
        updated_job_application =
          Repo.preload(
            updated_job_application,
            [:job_posting, :user, :media_asset],
            force: true
          )

        broadcast_event(
          "#{@job_application_topic}:company:#{job_application.job_posting.company_id}",
          "company_job_application_updated",
          %{job_application: updated_job_application}
        )

        broadcast_event(
          "#{@job_application_topic}:user:#{job_application.user_id}",
          "user_job_application_updated",
          %{job_application: updated_job_application}
        )

        {:ok, updated_job_application}

      {:error, _operation, changeset, _changes} ->
        {:error, changeset}
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

  @doc """
  Adds tags to a job application, creating any tags that don't exist.

  ## Examples

      iex> update_job_application_tags(job_application, ["urgent", "qualified"])
      {:ok, %JobApplication{}}

  """
  @spec update_job_application_tags(job_application(), tags()) ::
          {:ok, job_application()} | {:error, any()}
  def update_job_application_tags(%JobApplication{} = job_application, tags) do
    normalized_tags = normalize_tags(tags)

    job_application
    |> Repo.preload(:tags)
    |> execute_tag_application_transaction(normalized_tags)
    |> handle_tag_application_result()
  end

  defp normalize_tags(tags) do
    tags
    |> String.split(",")
    |> Stream.map(fn tag ->
      tag
      |> String.trim()
      |> String.downcase()
    end)
    |> Enum.reject(&(&1 == ""))
  end

  defp execute_tag_application_transaction(job_application, normalized_tags) do
    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:create_tags, fn _repo, _changes ->
        create_tags_query(normalized_tags)
      end)
      |> Ecto.Multi.run(:all_tags, fn _repo, _changes ->
        {:ok,
         Tag
         |> where([t], t.name in ^normalized_tags)
         |> Repo.all()}
      end)
      |> Ecto.Multi.run(:update_job_application, fn _repo, %{all_tags: all_tags} ->
        add_tags_to_job_application(job_application, all_tags)
      end)

    Repo.transaction(multi)
  end

  defp create_tags_query([]), do: {:ok, []}

  defp create_tags_query(tag_names) do
    timestamp = DateTime.utc_now(:second)

    placeholders = %{timestamp: timestamp}

    maps =
      Enum.map(
        tag_names,
        &%{
          name: &1,
          inserted_at: {:placeholder, :timestamp},
          updated_at: {:placeholder, :timestamp}
        }
      )

    Repo.insert_all(
      Tag,
      maps,
      placeholders: placeholders,
      on_conflict: :nothing
    )

    {:ok, tag_names}
  end

  defp add_tags_to_job_application(job_application, tags) do
    job_application
    |> change_job_application()
    |> Changeset.put_assoc(:tags, tags)
    |> Repo.update()
  end

  defp handle_tag_application_result({:ok, %{update_job_application: updated_job_application}}) do
    broadcast_job_application_update(updated_job_application)

    {:ok, updated_job_application}
  end

  defp handle_tag_application_result({:error, _operation, changeset, _changes}) do
    {:error, changeset}
  end

  defp broadcast_job_application_update(job_application) do
    broadcast_event(
      "#{@job_application_topic}:company:#{job_application.job_posting.company_id}",
      "company_job_application_updated",
      %{job_application: job_application}
    )

    broadcast_event(
      "#{@job_application_topic}:user:#{job_application.user_id}",
      "user_job_application_updated",
      %{job_application: job_application}
    )
  end

  defp broadcast_event(topic, event, message) do
    Endpoint.broadcast(
      topic,
      event,
      message
    )
  end

  defp needs_job_posting_join?(filters) do
    filters
    |> Map.keys()
    |> Enum.any?(fn key -> key in [:company_id, :job_title] end)
  end

  @spec update_job_application_status(job_application(), user(), attrs()) ::
          {:ok, job_application()} | {:error, changeset()}
  def update_job_application_status(job_application, user, attrs) do
    from_state = job_application.state
    to_state = Map.get(attrs, :to_state) || Map.get(attrs, "to_state")
    notes = Map.get(attrs, :notes) || Map.get(attrs, "notes")

    Multi.new()
    |> Multi.run(:job_application, fn _repo, _changes ->
      job_application
      |> Fsmx.transition_changeset(to_state)
      |> Repo.update()
    end)
    |> Multi.run(:job_application_state_transition, fn _repo,
                                                       %{job_application: job_application} ->
      create_job_application_state_transition(job_application, user, from_state, notes)
    end)
    |> Multi.run(:create_status_message, fn _repo,
                                            %{
                                              job_application_state_transition:
                                                job_application_state_transition
                                            } ->
      state = job_application_state_transition.to_state

      Chat.create_message(user, job_application_state_transition.job_application, %{
        content: state,
        type: "status_update"
      })
    end)
    |> Repo.transaction()
    |> handle_update_job_application_status_result()
  end

  defp create_job_application_state_transition(job_application, user, from_state, notes) do
    %JobApplicationStateTransition{}
    |> JobApplicationStateTransition.changeset(%{
      from_state: from_state,
      to_state: job_application.state,
      notes: notes
    })
    |> Changeset.put_assoc(:job_application, job_application)
    |> Changeset.put_assoc(:transitioned_by, user)
    |> Repo.insert()
  end

  defp handle_update_job_application_status_result({:ok, %{job_application: job_application}}) do
    broadcast_event(
      "#{@job_application_topic}:company:#{job_application.job_posting.company_id}",
      "company_job_application_status_updated",
      %{job_application: job_application}
    )

    broadcast_event(
      "#{@job_application_topic}:user:#{job_application.user_id}",
      "user_job_application_status_updated",
      %{job_application: job_application}
    )

    {:ok, job_application}
  end

  defp handle_update_job_application_status_result({:error, _operation, changeset, _changes}) do
    {:error, changeset}
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking job application state transition changes.

  ## Examples

      iex> change_job_application_status(job_application_state_transition)
      %Ecto.Changeset{data: %JobApplicationStateTransition{}}

  """
  @spec change_job_application_status(job_application_state_transition(), attrs()) ::
          changeset()
  def change_job_application_status(
        %JobApplicationStateTransition{} = job_application_state_transition,
        attrs \\ %{}
      ) do
    JobApplicationStateTransition.changeset(
      job_application_state_transition,
      attrs
    )
  end

  @doc """
  Lists all state transitions for a job application in chronological order.

  ## Examples

      iex> list_job_application_state_transitions(job_application)
      [%JobApplicationStateTransition{}, ...]

  """
  @spec list_job_application_state_transitions(job_application()) :: [
          JobApplicationStateTransition.t()
        ]
  def list_job_application_state_transitions(%JobApplication{} = job_application) do
    JobApplicationStateTransition
    |> where([t], t.job_application_id == ^job_application.id)
    |> order_by([t], desc: t.inserted_at)
    |> preload([:transitioned_by])
    |> Repo.all()
  end
end
