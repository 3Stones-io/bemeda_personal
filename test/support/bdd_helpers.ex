defmodule BemedaPersonal.BddHelpers do
  @moduledoc """
  Helper functions for BDD tests that need to be available across multiple step definition modules.

  Files in test/support/ are guaranteed to load before test files, preventing compilation order issues.
  """

  @doc """
  Generates a truly unique email for BDD tests running in shared database mode.
  Uses timestamp + multiple unique integers + random bytes to guarantee uniqueness.
  """
  @spec generate_unique_email(String.t()) :: String.t()
  def generate_unique_email(prefix) do
    timestamp = System.system_time(:microsecond)
    unique1 = System.unique_integer([:positive])
    unique2 = :erlang.unique_integer([:positive])
    random_bytes = :crypto.strong_rand_bytes(8)
    random = Base.encode16(random_bytes, case: :lower)
    "#{prefix}_#{timestamp}_#{unique1}_#{unique2}_#{random}@example.com"
  end
end
