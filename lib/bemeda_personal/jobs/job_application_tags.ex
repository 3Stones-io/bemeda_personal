defmodule BemedaPersonal.Jobs.JobApplicationTags do
  @moduledoc """
  Job application tagging functionality.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Jobs.JobApplication
  alias BemedaPersonal.Jobs.Tag
  alias BemedaPersonal.Repo
  alias BemedaPersonalWeb.Endpoint
  alias Ecto.Changeset

  @type job_application :: JobApplication.t()
  @type tags :: String.t()

  @job_application_topic "job_application"

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

  @doc """
  Normalizes a comma-separated string of tags into a list of clean, lowercase tags.

  ## Examples

      iex> normalize_tags("urgent, Qualified, ")
      ["urgent", "qualified"]

  """
  @spec normalize_tags(tags()) :: [String.t()]
  def normalize_tags(tags) do
    tags
    |> String.split(",")
    |> Stream.map(fn tag ->
      tag
      |> String.trim()
      |> String.downcase()
    end)
    |> Enum.reject(&(&1 == ""))
  end

  @doc """
  Executes the tag application transaction for a job application.

  ## Examples

      iex> execute_tag_application_transaction(job_application, ["urgent", "qualified"])
      {:ok, %{update_job_application: %JobApplication{}}}

  """
  @spec execute_tag_application_transaction(job_application(), [String.t()]) ::
          {:ok, map()} | {:error, any()}
  def execute_tag_application_transaction(job_application, normalized_tags) do
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

  @doc """
  Creates tags that don't already exist in the database.

  ## Examples

      iex> create_tags_query(["urgent", "qualified"])
      {:ok, ["urgent", "qualified"]}

  """
  @spec create_tags_query([String.t()]) :: {:ok, [String.t()]}
  def create_tags_query([]), do: {:ok, []}

  def create_tags_query(tag_names) do
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

  defp change_job_application(%JobApplication{} = job_application, attrs \\ %{}) do
    JobApplication.changeset(job_application, attrs)
  end

  defp handle_tag_application_result({:ok, %{update_job_application: updated_job_application}}) do
    broadcast_job_application_update(updated_job_application)
    {:ok, updated_job_application}
  end

  defp handle_tag_application_result({:error, reason}) do
    {:error, reason}
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
end
