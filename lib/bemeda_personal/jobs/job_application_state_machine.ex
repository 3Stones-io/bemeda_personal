defmodule BemedaPersonal.Jobs.JobApplicationStateMachine do
  @moduledoc false

  @behaviour Fsmx.Fsm

  @transitions %{
    "applied" => ["offer_extended", "withdrawn"],
    "offer_extended" => ["offer_accepted", "withdrawn"],
    "withdrawn" => ["applied", "offer_extended"]
  }

  use Fsmx.Fsm, transitions: @transitions

  @spec get_transitions() :: map()
  def get_transitions, do: @transitions
end
