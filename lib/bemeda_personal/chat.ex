defmodule BemedaPersonal.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Chat.Message
  alias BemedaPersonal.Jobs.JobApplication
  alias BemedaPersonal.Media
  alias BemedaPersonal.Repo
  alias BemedaPersonalWeb.Endpoint
  alias Ecto.Multi

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type job_application :: JobApplication.t()
  @type message :: Message.t()
  @type message_id :: Ecto.UUID.t()
  @type user :: User.t()

  @message_topic "messages"

  @doc """
  Returns a list of messages for a job application.

  ## Examples

      iex> list_messages(job_application)
      [%Message{}, ...]

  """
  @spec list_messages(job_application()) :: [message()]
  def list_messages(%JobApplication{} = job_application) do
    messages =
      Message
      |> where([m], m.job_application_id == ^job_application.id)
      |> order_by([m], asc: m.inserted_at)
      |> Repo.all()
      |> Repo.preload([:media_asset, :sender])

    maybe_load_user_resume(job_application, messages)
  end

  defp maybe_load_user_resume(job_application, messages) do
    job_application =
      Repo.preload(job_application, user: [resume: [:user, :educations, :work_experiences]])

    if job_application.user.resume && job_application.user.resume.is_public do
      [job_application, job_application.user.resume | messages]
    else
      [job_application | messages]
    end
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_message!(message_id()) :: message()
  def get_message!(id) do
    Message
    |> Repo.get!(id)
    |> Repo.preload([:media_asset, :sender, job_application: [job_posting: [:company]]])
  end

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(user, job_application, %{field: value})
      {:ok, %Message{}}

      iex> create_message(user, job_application, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_message(user(), job_application(), attrs()) ::
          {:ok, message()} | {:error, changeset()}
  def create_message(%User{} = sender, %JobApplication{} = job_application, attrs) do
    result =
      %Message{}
      |> Message.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:sender, sender)
      |> Ecto.Changeset.put_assoc(:job_application, job_application)
      |> Repo.insert()

    case result do
      {:ok, message} ->
        message_topic = "#{@message_topic}:job_application:#{job_application.id}"
        Endpoint.broadcast(message_topic, "message_created", %{message: message})

        {:ok, message}

      error ->
        error
    end
  end

  @doc """
  Creates a message with associated media asset in a transaction.

  ## Examples

      iex> create_message_with_media(user, job_application, %{field: value, media_data: %{}})
      {:ok, %Message{}}

      iex> create_message_with_media(user, job_application, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_message_with_media(user(), job_application(), attrs()) ::
          {:ok, message()} | {:error, changeset()}
  def create_message_with_media(%User{} = sender, %JobApplication{} = job_application, attrs) do
    changeset =
      %Message{}
      |> Message.changeset(%{})
      |> Ecto.Changeset.put_assoc(:sender, sender)
      |> Ecto.Changeset.put_assoc(:job_application, job_application)

    multi =
      Multi.new()
      |> Multi.insert(:message, changeset)
      |> Multi.run(:media_asset, fn _repo, %{message: message} ->
        case Map.get(attrs, "media_data") do
          nil -> {:ok, nil}
          media_data -> Media.create_media_asset(message, media_data)
        end
      end)

    case Repo.transaction(multi) do
      {:ok, %{message: message}} ->
        message =
          Repo.preload(
            message,
            [:sender, :job_application, :media_asset],
            force: true
          )

        message_topic = "#{@message_topic}:job_application:#{job_application.id}"
        Endpoint.broadcast(message_topic, "message_created", %{message: message})

        {:ok, message}

      {:error, _operation, changeset, _changes} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_message(message(), attrs()) :: {:ok, message()} | {:error, changeset()}
  def update_message(%Message{} = message, attrs) do
    result =
      message
      |> Message.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated_message} ->
        message_topic = "#{@message_topic}:job_application:#{updated_message.job_application_id}"

        Endpoint.broadcast(
          message_topic,
          "message_updated",
          %{message: updated_message}
        )

        {:ok, updated_message}

      error ->
        error
    end
  end

  @doc """
  Deletes a message.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_message(message()) :: {:ok, message()} | {:error, changeset()}
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{data: %Message{}}

  """
  @spec change_message(message(), attrs()) :: changeset()
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end
end
