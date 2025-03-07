defmodule BemedaPersonal.Resumes do
  @moduledoc """
  The Resumes context.

  This context handles all operations related to user resumes, including
  education, work experience, and skills.
  """

  import Ecto.Query, warn: false
  alias BemedaPersonal.Repo
  alias Ecto.Changeset

  alias BemedaPersonal.Resumes.Education
  alias BemedaPersonal.Resumes.Resume
  alias BemedaPersonal.Resumes.WorkExperience

  # Custom types for type specifications
  @type changeset :: Ecto.Changeset.t()
  @type education :: Education.t()
  @type resume :: Resume.t()
  @type user :: BemedaPersonal.Accounts.User.t()
  @type uuid :: Ecto.UUID.t()
  @type work_experience :: WorkExperience.t()

  @doc """
  Gets or creates a resume for a user.

  If the user already has a resume, returns it.
  If the user doesn't have a resume, creates one and returns it.

  ## Examples

      iex> get_or_create_resume_by_user(user)
      %Resume{}

  """
  @spec get_or_create_resume_by_user(user()) :: resume()
  def get_or_create_resume_by_user(user) do
    case Repo.get_by(Resume, user_id: user.id) do
      nil ->
        %Resume{}
        |> Resume.changeset()
        |> Ecto.Changeset.put_assoc(:user, user)
        |> Repo.insert!()

      resume ->
        resume
    end
  end

  @doc """
  Gets a single resume.

  Returns nil if the Resume does not exist.

  ## Examples

      iex> get_resume(123)
      %Resume{}

      iex> get_resume(456)
      nil

  """
  @spec get_resume(uuid()) :: resume() | nil
  def get_resume(id) do
    Resume
    |> Repo.get(id)
    |> Repo.preload([:user, :educations, :work_experiences])
  end

  @doc """
  Updates a resume.

  ## Examples

      iex> update_resume(resume, %{field: new_value})
      {:ok, %Resume{}}

      iex> update_resume(resume, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_resume(resume(), map()) :: {:ok, resume()} | {:error, changeset()}
  def update_resume(%Resume{} = resume, attrs) do
    resume
    |> Resume.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking resume changes.

  ## Examples

      iex> change_resume(resume)
      %Ecto.Changeset{data: %Resume{}}

  """
  @spec change_resume(resume(), map()) :: changeset()
  def change_resume(%Resume{} = resume, attrs \\ %{}) do
    Resume.changeset(resume, attrs)
  end

  # Education functions

  @doc """
  Returns the list of educations for a resume.

  ## Examples

      iex> list_educations(resume_id)
      [%Education{}, ...]

  """
  @spec list_educations(uuid()) :: [education()]
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

      iex> get_education!(123)
      %Education{}

      iex> get_education!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_education!(uuid()) :: education()
  def get_education!(id) do
    Education
    |> Repo.get!(id)
    |> Repo.preload(:resume)
  end

  @doc """
  Creates or updates an education entry.

  ## Examples

      iex> create_or_update_education(%Education{}, %Resume{}, %{field: value})
      {:ok, %Education{}}

      iex> create_or_update_education(%Education{}, %Resume{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_or_update_education(education(), resume(), map()) ::
          {:ok, education()} | {:error, changeset()}
  def create_or_update_education(education, resume, attrs \\ %{}) do
    education
    |> Education.changeset(attrs)
    |> Changeset.put_assoc(:resume, resume)
    |> Repo.insert_or_update()
  end

  @doc """
  Deletes an education entry.

  ## Examples

      iex> delete_education(education)
      {:ok, %Education{}}

      iex> delete_education(education)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_education(education()) :: {:ok, education()} | {:error, changeset()}
  def delete_education(%Education{} = education) do
    Repo.delete(education)
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
  @spec list_work_experiences(uuid()) :: [work_experience()]
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

      iex> get_work_experience!(123)
      %WorkExperience{}

      iex> get_work_experience!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_work_experience!(uuid()) :: work_experience()
  def get_work_experience!(id) do
    WorkExperience
    |> Repo.get!(id)
    |> Repo.preload(:resume)
  end

  @doc """
  Creates or updates a work experience entry.

  ## Examples

      iex> create_or_update_work_experience(%WorkExperience{}, %Resume{}, %{field: value})
      {:ok, %WorkExperience{}}

      iex> create_or_update_work_experience(%WorkExperience{}, %Resume{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_or_update_work_experience(work_experience(), resume(), map()) ::
          {:ok, work_experience()} | {:error, changeset()}
  def create_or_update_work_experience(work_experience, resume, attrs \\ %{}) do
    work_experience
    |> WorkExperience.changeset(attrs)
    |> Changeset.put_assoc(:resume, resume)
    |> Repo.insert_or_update()
  end

  @doc """
  Deletes a work experience entry.

  ## Examples

      iex> delete_work_experience(work_experience)
      {:ok, %WorkExperience{}}

      iex> delete_work_experience(work_experience)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_work_experience(work_experience()) ::
          {:ok, work_experience()} | {:error, changeset()}
  def delete_work_experience(%WorkExperience{} = work_experience) do
    Repo.delete(work_experience)
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
