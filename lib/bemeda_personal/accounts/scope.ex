defmodule BemedaPersonal.Accounts.Scope do
  @moduledoc """
  Scope structure for secure data access.
  Contains user and optionally company information for filtering queries.
  """

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies.Company

  @type t :: %__MODULE__{
          user: User.t() | nil,
          company: Company.t() | nil,
          state: String.t() | nil,
          system: boolean()
        }

  defstruct user: nil, company: nil, state: nil, system: false

  @doc """
  Creates a scope for a user
  """
  @spec for_user(User.t() | nil) :: t() | nil
  def for_user(%User{} = user) do
    %__MODULE__{user: user}
  end

  def for_user(nil), do: nil

  @doc """
  Creates a system scope for background workers and system operations
  """
  @spec system() :: t()
  def system do
    %__MODULE__{system: true}
  end

  @doc """
  Adds company to existing scope
  """
  @spec put_company(t(), Company.t()) :: t()
  def put_company(%__MODULE__{} = scope, %Company{} = company) do
    %{scope | company: company}
  end

  @doc """
  Adds state to existing scope
  """
  @spec put_state(t(), String.t()) :: t()
  def put_state(%__MODULE__{} = scope, state) when is_binary(state) do
    %{scope | state: state}
  end

  @doc """
  Helper to get user_id from scope
  """
  @spec user_id(t()) :: String.t() | nil
  def user_id(%__MODULE__{user: %User{id: id}}), do: id
  def user_id(%__MODULE__{}), do: nil

  @doc """
  Helper to get company_id from scope
  """
  @spec company_id(t()) :: String.t() | nil
  def company_id(%__MODULE__{company: %Company{id: id}}), do: id
  def company_id(%__MODULE__{}), do: nil

  @doc """
  Checks if scope has required access
  """
  @spec has_access?(t(), atom()) :: boolean()
  def has_access?(%__MODULE__{system: true}, :system), do: true
  def has_access?(%__MODULE__{user: nil}, :user), do: false
  def has_access?(%__MODULE__{user: %User{}}, :user), do: true
  def has_access?(%__MODULE__{company: nil}, :company), do: false
  def has_access?(%__MODULE__{company: %Company{}}, :company), do: true
  def has_access?(_scope, _access_type), do: false
end
