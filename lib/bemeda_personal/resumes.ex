defmodule BemedaPersonal.Resumes do
  @moduledoc """
  The Resumes context.

  This context handles all operations related to user resumes, including
  education and work experience.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Repo
  alias BemedaPersonal.Resumes.Education
  alias BemedaPersonal.Resumes.Resume
  alias BemedaPersonal.Resumes.WorkExperience
  alias Ecto.Changeset

  @type changeset :: Ecto.Changeset.t()
  @type education :: Education.t()
  @type education_id :: Ecto.UUID.t()
  @type resume :: Resume.t()
  @type resume_id :: Ecto.UUID.t()
  @type scope :: Scope.t()
  @type user :: BemedaPersonal.Accounts.User.t()
  @type work_experience :: WorkExperience.t()
  @type work_experience_id :: Ecto.UUID.t()

  @doc """
  Subscribes to scoped notifications about any resume changes.

  The broadcasted messages match the pattern:

    * {:created, %Resume{}}
    * {:updated, %Resume{}}
    * {:deleted, %Resume{}}

  """
  @spec subscribe_resumes(scope()) :: :ok
  def subscribe_resumes(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(BemedaPersonal.PubSub, "user:#{key}:resumes")
  end

  @doc """
  Subscribes to scoped notifications about education changes.

  The broadcasted messages match the pattern:

    * {:created, %Education{}}
    * {:updated, %Education{}}
    * {:deleted, %Education{}}

  """
  @spec subscribe_educations(scope()) :: :ok
  def subscribe_educations(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(BemedaPersonal.PubSub, "user:#{key}:educations")
  end

  @doc """
  Subscribes to scoped notifications about work experience changes.

  The broadcasted messages match the pattern:

    * {:created, %WorkExperience{}}
    * {:updated, %WorkExperience{}}
    * {:deleted, %WorkExperience{}}

  """
  @spec subscribe_work_experiences(scope()) :: :ok
  def subscribe_work_experiences(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(BemedaPersonal.PubSub, "user:#{key}:work_experiences")
  end

  defp broadcast_resume(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(BemedaPersonal.PubSub, "user:#{key}:resumes", message)
  end

  defp broadcast_education(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(BemedaPersonal.PubSub, "user:#{key}:educations", message)
  end

  defp broadcast_work_experience(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(BemedaPersonal.PubSub, "user:#{key}:work_experiences", message)
  end

  @doc """
  Gets or creates a resume for a user.

  If the user already has a resume, returns it.
  If the user doesn't have a resume, creates one and returns it.

  ## Examples

      iex> get_or_create_resume_by_user(scope)
      %Resume{}

  """
  @spec get_or_create_resume_by_user(scope()) :: resume()
  def get_or_create_resume_by_user(%Scope{} = scope) do
    case Repo.get_by(Resume, user_id: scope.user.id) do
      nil ->
        resume =
          %Resume{}
          |> Resume.changeset()
          |> Changeset.put_assoc(:user, scope.user)
          |> Repo.insert!()

        broadcast_resume(scope, {:created, resume})
        resume

      resume ->
        resume
    end
  end

  @doc """
  Gets a single resume.

  Raises `Ecto.NoResultsError` if the Resume does not exist or doesn't belong to the user.

  ## Examples

      iex> get_resume!(scope, 123)
      %Resume{}

      iex> get_resume!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  @spec get_resume!(scope() | nil, resume_id()) :: resume()
  def get_resume!(%Scope{} = scope, id) do
    Resume
    |> where([r], r.id == ^id and r.user_id == ^scope.user.id)
    |> Repo.one!()
    |> Repo.preload([:user, :educations, :work_experiences])
  end

  def get_resume!(nil, id) do
    Resume
    |> where([r], r.id == ^id and r.is_public == true)
    |> Repo.one!()
    |> Repo.preload([:user, :educations, :work_experiences])
  end

  @doc """
  Gets a user's resume.

  Returns nil if the user does not have a resume.

  ## Examples

      iex> get_user_resume(user)
      %Resume{}

      iex> get_user_resume(user)
      nil

  """
  @spec get_user_resume(user()) :: resume() | nil
  def get_user_resume(user) do
    Resume
    |> where([r], r.user_id == ^user.id)
    |> Repo.one()
    |> Repo.preload([:user, :educations, :work_experiences])
  end

  @doc """
  Updates a resume.

  ## Examples

      iex> update_resume(scope, resume, %{field: new_value})
      {:ok, %Resume{}}

      iex> update_resume(scope, resume, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_resume(scope(), resume(), map()) :: {:ok, resume()} | {:error, changeset()}
  def update_resume(%Scope{} = scope, %Resume{} = resume, attrs) do
    true = resume.user_id == scope.user.id

    result =
      resume
      |> Resume.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated_resume} ->
        broadcast_resume(scope, {:updated, updated_resume})
        {:ok, updated_resume}

      error ->
        error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking resume changes.

  ## Examples

      iex> change_resume(scope, resume)
      %Ecto.Changeset{data: %Resume{}}

  """
  @spec change_resume(scope(), resume(), map()) :: changeset()
  def change_resume(%Scope{} = scope, %Resume{} = resume, attrs \\ %{}) do
    true = resume.user_id == scope.user.id

    Resume.changeset(resume, attrs)
  end

  # Education functions

  @doc """
  Returns the list of educations for a resume.

  ## Examples

      iex> list_educations(resume_id)
      [%Education{}, ...]

  """
  @spec list_educations(resume_id()) :: [education()]
  def list_educations(resume_id) do
    Education
    |> where([e], e.resume_id == ^resume_id)
    |> order_by([e], desc: e.current, desc: e.start_date)
    |> Repo.all()
    |> Repo.preload(:resume)
  end

  @doc """
  Gets a single education entry.

  Raises `Ecto.NoResultsError` if the Education does not exist.

  ## Examples

      iex> get_education(123)
      %Education{}

      iex> get_education(456)
      nil

  """
  @spec get_education(education_id()) :: education() | nil
  def get_education(id) do
    Education
    |> Repo.get(id)
    |> Repo.preload(:resume)
  end

  @doc """
  Gets a single education entry.

  Raises `Ecto.NoResultsError` if the Education does not exist or doesn't belong to the user.

  ## Examples

      iex> get_education!(scope, 123)
      %Education{}

      iex> get_education!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  @spec get_education!(scope(), education_id()) :: education()
  def get_education!(%Scope{} = scope, id) do
    Education
    |> join(:inner, [e], r in Resume, on: e.resume_id == r.id)
    |> where([e, r], e.id == ^id and r.user_id == ^scope.user.id)
    |> Repo.one!()
    |> Repo.preload(:resume)
  end

  @doc """
  Creates or updates an education entry.

  ## Examples

      iex> create_or_update_education(scope, %Education{}, %Resume{}, %{field: value})
      {:ok, %Education{}}

      iex> create_or_update_education(scope, %Education{}, %Resume{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_or_update_education(scope(), education(), resume(), map()) ::
          {:ok, education()} | {:error, changeset()}
  def create_or_update_education(%Scope{} = scope, education, resume, attrs \\ %{}) do
    true = resume.user_id == scope.user.id

    result =
      education
      |> Education.changeset(attrs)
      |> Changeset.put_assoc(:resume, resume)
      |> Repo.insert_or_update()

    case result do
      {:ok, updated_education} ->
        event = if updated_education.id == education.id, do: :updated, else: :created
        broadcast_education(scope, {event, updated_education})
        {:ok, updated_education}

      error ->
        error
    end
  end

  @doc """
  Deletes an education entry.

  ## Examples

      iex> delete_education(scope, education)
      {:ok, %Education{}}

      iex> delete_education(scope, education)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_education(scope(), education()) :: {:ok, education()} | {:error, changeset()}
  def delete_education(%Scope{} = scope, %Education{} = education) do
    education = Repo.preload(education, :resume)
    true = education.resume.user_id == scope.user.id

    result = Repo.delete(education)

    case result do
      {:ok, deleted_education} ->
        broadcast_education(scope, {:deleted, deleted_education})
        {:ok, deleted_education}

      error ->
        error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking education changes.

  ## Examples

      iex> change_education(education)
      %Ecto.Changeset{data: %Education{}}

  """
  @spec change_education(education(), map()) :: changeset()
  def change_education(%Education{} = education, attrs \\ %{}) do
    Education.changeset(education, attrs)
  end

  # Work Experience functions

  @doc """
  Returns the list of work experiences for a resume.

  ## Examples

      iex> list_work_experiences(resume_id)
      [%WorkExperience{}, ...]

  """
  @spec list_work_experiences(resume_id()) :: [work_experience()]
  def list_work_experiences(resume_id) do
    WorkExperience
    |> where([w], w.resume_id == ^resume_id)
    |> order_by([w], desc: w.current, desc: w.start_date)
    |> Repo.all()
    |> Repo.preload(:resume)
  end

  @doc """
  Gets a single work experience entry.

  Raises `Ecto.NoResultsError` if the WorkExperience does not exist.

  ## Examples

      iex> get_work_experience(123)
      %WorkExperience{}

      iex> get_work_experience(456)
      nil

  """
  @spec get_work_experience(work_experience_id()) :: work_experience() | nil
  def get_work_experience(id) do
    WorkExperience
    |> Repo.get(id)
    |> Repo.preload(:resume)
  end

  @doc """
  Gets a single work experience entry.

  Raises `Ecto.NoResultsError` if the WorkExperience does not exist or doesn't belong to the user.

  ## Examples

      iex> get_work_experience!(scope, 123)
      %WorkExperience{}

      iex> get_work_experience!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  @spec get_work_experience!(scope(), work_experience_id()) :: work_experience()
  def get_work_experience!(%Scope{} = scope, id) do
    WorkExperience
    |> join(:inner, [w], r in Resume, on: w.resume_id == r.id)
    |> where([w, r], w.id == ^id and r.user_id == ^scope.user.id)
    |> Repo.one!()
    |> Repo.preload(:resume)
  end

  @doc """
  Creates or updates a work experience entry.

  ## Examples

      iex> create_or_update_work_experience(scope, %WorkExperience{}, %Resume{}, %{field: value})
      {:ok, %WorkExperience{}}

      iex> create_or_update_work_experience(scope, %WorkExperience{}, %Resume{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_or_update_work_experience(scope(), work_experience(), resume(), map()) ::
          {:ok, work_experience()} | {:error, changeset()}
  def create_or_update_work_experience(%Scope{} = scope, work_experience, resume, attrs \\ %{}) do
    true = resume.user_id == scope.user.id

    result =
      work_experience
      |> WorkExperience.changeset(attrs)
      |> Changeset.put_assoc(:resume, resume)
      |> Repo.insert_or_update()

    case result do
      {:ok, updated_work_experience} ->
        event = if updated_work_experience.id == work_experience.id, do: :updated, else: :created
        broadcast_work_experience(scope, {event, updated_work_experience})
        {:ok, updated_work_experience}

      error ->
        error
    end
  end

  @doc """
  Deletes a work experience entry.

  ## Examples

      iex> delete_work_experience(scope, work_experience)
      {:ok, %WorkExperience{}}

      iex> delete_work_experience(scope, work_experience)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_work_experience(scope(), work_experience()) ::
          {:ok, work_experience()} | {:error, changeset()}
  def delete_work_experience(%Scope{} = scope, %WorkExperience{} = work_experience) do
    work_experience = Repo.preload(work_experience, :resume)
    true = work_experience.resume.user_id == scope.user.id

    result = Repo.delete(work_experience)

    case result do
      {:ok, deleted_work_experience} ->
        broadcast_work_experience(scope, {:deleted, deleted_work_experience})
        {:ok, deleted_work_experience}

      error ->
        error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking work experience changes.

  ## Examples

      iex> change_work_experience(work_experience)
      %Ecto.Changeset{data: %WorkExperience{}}

  """
  @spec change_work_experience(work_experience(), map()) :: changeset()
  def change_work_experience(%WorkExperience{} = work_experience, attrs \\ %{}) do
    WorkExperience.changeset(work_experience, attrs)
  end
end
