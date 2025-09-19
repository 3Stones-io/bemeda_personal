defmodule BemedaPersonal.Accounts.MagicLinkToken do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Query

  @type context :: String.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @magic_link_validity_in_minutes 15
  @sudo_validity_in_minutes 5

  schema "magic_link_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    field :used_at, :utc_datetime

    belongs_to :user, BemedaPersonal.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Generates a token for magic link authentication
  """
  @spec build_magic_link_token(BemedaPersonal.Accounts.User.t(), context()) :: t()
  def build_magic_link_token(user, context \\ "magic_link") do
    token = :crypto.strong_rand_bytes(32)

    %__MODULE__{
      token: token,
      context: to_string(context),
      sent_to: user.email,
      user_id: user.id
    }
  end

  @doc """
  Checks if a magic link token is valid
  """
  @spec verify_magic_link_token_query(binary(), context()) :: {:ok, Ecto.Query.t()}
  def verify_magic_link_token_query(token, context) do
    query =
      from token in __MODULE__,
        join: user in assoc(token, :user),
        where: token.token == ^token,
        where: token.context == ^context,
        where: is_nil(token.used_at),
        where: token.inserted_at > ago(@magic_link_validity_in_minutes, "minute"),
        select: token

    {:ok, query}
  end

  @doc """
  Marks token as used
  """
  @spec mark_as_used(t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def mark_as_used(token) do
    token
    |> Ecto.Changeset.change(used_at: DateTime.utc_now(:second))
    |> BemedaPersonal.Repo.update()
  end

  @doc """
  Returns validity period based on context
  """
  @spec validity_in_minutes(context()) :: integer()
  def validity_in_minutes("sudo"), do: @sudo_validity_in_minutes
  def validity_in_minutes(_context), do: @magic_link_validity_in_minutes
end
