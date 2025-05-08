defmodule BemedaPersonal.Jobs.JobApplicationStateMachine do
  @moduledoc false

  @behaviour Fsmx.Fsm

  use Fsmx.Fsm,
    transitions: %{
      "applied" => ["under_review", "withdrawn", "rejected"],
      "under_review" => ["screening", "withdrawn", "rejected"],
      "screening" => ["interview_scheduled", "withdrawn", "rejected"],
      "interview_scheduled" => ["interviewed", "withdrawn", "rejected"],
      "interviewed" => ["offer_extended", "withdrawn", "rejected"],
      "offer_extended" => ["offer_accepted", "offer_declined", "withdrawn"],
      "offer_accepted" => [],
      "offer_declined" => [],
      "withdrawn" => []
    }
end
