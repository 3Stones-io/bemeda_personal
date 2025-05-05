defmodule BemedaPersonal.Jobs.JobApplicationStateMachine do
  @moduledoc false

  @behaviour Fsmx.Fsm

  use Fsmx.Fsm,
    transitions: %{
      "applied" => ["under_review", "withdrawn", "rejected"],
      "under_review" => ["screening", "withdrawn", "rejected"],
      "screening" => ["interview_scheduled", "withdrawn", "rejected"],
      "interview_scheduled" => ["interviewed", "withdrawn", "rejected"],
      "interviewed" => ["offer_pending", "withdrawn", "rejected"],
      "offer_pending" => ["offer_extended", "withdrawn", "rejected"],
      "offer_extended" => ["offer_accepted", "offer_declined", "withdrawn"],
      "offer_accepted" => [],
      "offer_declined" => [],
      "withdrawn" => [],
      "rejected" => []
    },
    state_field: :state

  import Ecto.Changeset, only: [cast: 3]

  @impl Fsmx.Fsm
  def transition_changeset(struct_or_changeset, _from_state, _to_state, _event, params)
      when is_map(params) do
    cast(struct_or_changeset, params, [:notes])
  end

  @impl Fsmx.Fsm
  def before_transition(
        %{user_id: user_id} = job_application,
        _from_state,
        "withdrawn",
        _state_field
      ) do
    current_user = Map.get(job_application, :current_user)

    if current_user && user_id == current_user.id do
      {:ok, job_application}
    else
      {:error, "You are not authorized to perform this transition"}
    end
  end

  @impl Fsmx.Fsm
  def before_transition(
        %{user_id: user_id} = job_application,
        "interview_scheduled",
        "rejected",
        _state_field
      ) do
    current_user = Map.get(job_application, :current_user)

    if current_user && user_id == current_user.id do
      {:ok, job_application}
    else
      {:error, "You are not authorized to perform this transition"}
    end
  end

  @impl Fsmx.Fsm
  def before_transition(
        %{user_id: user_id} = job_application,
        "offer_pending",
        "rejected",
        _state_field
      ) do
    current_user = Map.get(job_application, :current_user)

    if current_user && user_id == current_user.id do
      {:ok, job_application}
    else
      {:error, "You are not authorized to perform this transition"}
    end
  end

  @impl Fsmx.Fsm
  def before_transition(
        %{user_id: user_id} = job_application,
        "offer_extended",
        "offer_declined",
        _state_field
      ) do
    current_user = Map.get(job_application, :current_user)

    if current_user && user_id == current_user.id do
      {:ok, job_application}
    else
      {:error, "You are not authorized to perform this transition"}
    end
  end

  @impl Fsmx.Fsm
  def before_transition(
        %{job_posting: %{company: %{admin_user_id: admin_id}}} = job_application,
        _from_state,
        _to_state,
        _state_field
      ) do
    current_user = Map.get(job_application, :current_user)

    if current_user && admin_id == current_user.id do
      {:ok, job_application}
    else
      {:error, "You are not authorized to perform this transition"}
    end
  end

  @impl Fsmx.Fsm
  def before_transition(job_application, _from_state, _to_state, _state_field) do
    {:ok, job_application}
  end
end
