defmodule BemedaPersonal.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Chat.Message
  alias BemedaPersonal.Jobs.JobApplication
  alias BemedaPersonal.Repo
  alias Phoenix.PubSub

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type job_application :: JobApplication.t()
  @type message :: Message.t()
  @type message_id :: Ecto.UUID.t()
  @type user :: User.t()

  @message_topic "message"

  @doc """
  Returns a list of messages for a job application.

  ## Examples

      iex> list_messages(job_application)
      [%Message{}, ...]

  """
  @spec list_messages(job_application()) :: [message()]
  def list_messages(%JobApplication{} = job_application) do
    Message
    |> where([m], m.job_application_id == ^job_application.id)
    |> order_by([m], asc: m.inserted_at)
    |> Repo.all()
    |> Repo.preload(:sender)
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
    |> Repo.preload([:sender, :job_application])
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
        PubSub.broadcast(BemedaPersonal.PubSub, message_topic, {:new_message, message})
        {:ok, message}

      error ->
        error
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
    message
    |> Message.changeset(attrs)
    |> Repo.update()
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
