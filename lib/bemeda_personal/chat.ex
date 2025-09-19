defmodule BemedaPersonal.Chat do
  @moduledoc """
  The Chat context.
  """

  use BemedaPersonalWeb, :verified_routes

  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Chat.Message
  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.Media
  alias BemedaPersonal.Repo
  alias BemedaPersonalWeb.Endpoint
  alias BemedaPersonalWeb.SharedHelpers
  alias Ecto.Multi

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type job_application :: JobApplication.t()
  @type message :: Message.t()
  @type message_id :: Ecto.UUID.t()
  @type scope :: Scope.t()
  @type user :: User.t()

  @message_topic "messages"

  @doc """
  Returns a list of messages for a job application with scope filtering.

  Users can only see messages for job applications they have access to.

  ## Examples

      iex> list_messages(scope, job_application)
      [%Message{}, ...]

  """
  @spec list_messages(scope(), job_application()) :: [message()]
  def list_messages(%Scope{} = scope, %JobApplication{} = job_application) do
    # Validate user has access to this job application
    unless JobApplications.has_job_application_access?(scope, job_application) do
      raise "Access denied to job application"
    end

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
  Gets a single message with scope filtering.

  Raises `Ecto.NoResultsError` if the Message does not exist or user has no access.

  ## Examples

      iex> get_message!(scope, 123)
      %Message{}

      iex> get_message!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  @spec get_message!(scope(), message_id()) :: message()
  def get_message!(%Scope{} = scope, id) do
    message =
      Message
      |> Repo.get!(id)
      |> Repo.preload([:media_asset, :sender, job_application: [job_posting: [:company]]])

    # Validate user has access to this message's job application
    unless JobApplications.has_job_application_access?(scope, message.job_application) do
      raise "Access denied to message"
    end

    message
  end

  @doc """
  Creates a message with scope validation.

  ## Examples

      iex> create_message(scope, user, job_application, %{field: value})
      {:ok, %Message{}}

      iex> create_message(scope, user, job_application, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_message(scope(), user(), job_application(), attrs()) ::
          {:ok, message()} | {:error, changeset()}
  def create_message(
        %Scope{} = scope,
        %User{} = sender,
        %JobApplication{} = job_application,
        attrs
      ) do
    # Validate user has access to this job application
    unless JobApplications.has_job_application_access?(scope, job_application) do
      raise "Access denied to job application"
    end

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

        # Enqueue email notification for new messages
        if message.type == :user do
          enqueue_message_notification(message, job_application)
        end

        {:ok, message}

      error ->
        error
    end
  end

  @doc """
  Creates a message with associated media asset in a transaction with scope validation.

  ## Examples

      iex> create_message_with_media(scope, user, job_application, %{field: value, media_data: %{}})
      {:ok, %Message{}}

      iex> create_message_with_media(scope, user, job_application, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_message_with_media(scope(), user(), job_application(), attrs()) ::
          {:ok, message()} | {:error, changeset()}
  def create_message_with_media(
        %Scope{} = scope,
        %User{} = sender,
        %JobApplication{} = job_application,
        attrs
      ) do
    # Validate user has access to this job application
    unless JobApplications.has_job_application_access?(scope, job_application) do
      raise "Access denied to job application"
    end

    multi = build_message_with_media_multi(sender, job_application, attrs)

    case Repo.transaction(multi) do
      {:ok, %{message: message}} ->
        handle_successful_message_creation(message, job_application)

      {:error, _operation, changeset, _changes} ->
        {:error, changeset}
    end
  end

  defp build_message_with_media_multi(sender, job_application, attrs) do
    content_attrs = Map.take(attrs, ["content"])

    changeset =
      %Message{}
      |> Message.changeset(content_attrs)
      |> Ecto.Changeset.put_assoc(:sender, sender)
      |> Ecto.Changeset.put_assoc(:job_application, job_application)

    Multi.new()
    |> Multi.insert(:message, changeset)
    |> Multi.run(:media_asset, fn _repo, %{message: message} ->
      case Map.get(attrs, "media_data") do
        nil -> {:ok, nil}
        media_data -> Media.create_media_asset(message, media_data)
      end
    end)
  end

  defp handle_successful_message_creation(message, job_application) do
    message =
      Repo.preload(
        message,
        [:sender, :job_application, :media_asset],
        force: true
      )

    broadcast_message_created(message, job_application)
    maybe_enqueue_email_notification(message, job_application)

    {:ok, message}
  end

  defp broadcast_message_created(message, job_application) do
    message_topic = "#{@message_topic}:job_application:#{job_application.id}"
    Endpoint.broadcast(message_topic, "message_created", %{message: message})
  end

  defp maybe_enqueue_email_notification(message, job_application) do
    if message.type == :user do
      enqueue_message_notification(message, job_application)
    end
  end

  @doc """
  Updates a message with scope validation.

  ## Examples

      iex> update_message(scope, message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(scope, message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_message(scope(), message(), attrs()) :: {:ok, message()} | {:error, changeset()}
  def update_message(%Scope{} = scope, %Message{} = message, attrs) do
    # Load job application to validate access
    message = Repo.preload(message, job_application: [job_posting: [:company]])

    # Validate user has access to this message's job application
    unless JobApplications.has_job_application_access?(scope, message.job_application) do
      raise "Access denied to message"
    end

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
  Deletes a message with scope validation.

  ## Examples

      iex> delete_message(scope, message)
      {:ok, %Message{}}

      iex> delete_message(scope, message)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_message(scope(), message()) :: {:ok, message()} | {:error, changeset()}
  def delete_message(%Scope{} = scope, %Message{} = message) do
    # Load job application to validate access
    message = Repo.preload(message, job_application: [job_posting: [:company]])

    # Validate user has access to this message's job application
    unless JobApplications.has_job_application_access?(scope, message.job_application) do
      raise "Access denied to message"
    end

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

  # Private function to enqueue email notification for messages
  defp enqueue_message_notification(message, job_application) do
    # Load necessary associations
    job_application =
      Repo.preload(job_application, job_posting: [:company])

    recipient_id =
      if message.sender_id == job_application.job_posting.company.admin_user_id do
        job_application.user_id
      else
        job_application.job_posting.company.admin_user_id
      end

    SharedHelpers.enqueue_email_notification_job(%{
      message_id: message.id,
      recipient_id: recipient_id,
      type: "new_message",
      url: ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
    })
  end
end
