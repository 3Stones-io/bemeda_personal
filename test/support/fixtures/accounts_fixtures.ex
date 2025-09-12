defmodule BemedaPersonal.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.Accounts` context.
  """

  import Ecto.Query

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Repo

  @type attrs :: keyword()

  @default_locale Application.compile_env!(:bemeda_personal, BemedaPersonalWeb.Gettext)[
                    :default_locale
                  ]

  @spec unique_user_email() :: String.t()
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  @spec valid_user_password() :: String.t()
  def valid_user_password, do: "securepassword123"

  @spec valid_user_attributes(attrs()) :: map()
  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      profile: %{
        first_name: "John",
        last_name: "Doe",
        date_of_birth: ~D[1990-01-01],
        gender: :male,
        phone: "+41 79 123 45 67"
      }
    })
  end

  def unconfirmed_user_fixture(attrs \\ %{locale: "en"}) do
    {:ok, user} =
      attrs
      |> maybe_set_locale()
      |> valid_user_attributes()
      |> Accounts.register_user()

    user
  end

  def user_fixture(attrs \\ %{}) do
    user = unconfirmed_user_fixture(attrs)

    token =
      extract_user_token(fn url ->
        Accounts.deliver_login_instructions(user, url)
      end)

    {:ok, {user, _expired_tokens}} =
      Accounts.login_user_by_magic_link(token)

    user
  end

  def user_scope_fixture do
    user = user_fixture()
    user_scope_fixture(user)
  end

  def user_scope_fixture(user) do
    Scope.for_user(user)
  end

  def set_password(user) do
    {:ok, {user, _expired_tokens}} =
      Accounts.update_user_password(user, %{password: valid_user_password()})

    user
  end

  @spec extract_user_token(function()) :: String.t()
  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_start, token | _end] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def override_token_authenticated_at(token, authenticated_at) when is_binary(token) do
    Repo.update_all(
      from(t in Accounts.UserToken,
        where: t.token == ^token
      ),
      set: [authenticated_at: authenticated_at]
    )
  end

  @spec generate_user_magic_link_token(any()) :: {binary(), binary()}
  def generate_user_magic_link_token(user) do
    {encoded_token, user_token} = Accounts.UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    {encoded_token, user_token.token}
  end

  def offset_user_token(token, amount_to_add, unit) do
    dt = DateTime.add(DateTime.utc_now(:second), amount_to_add, unit)

    Repo.update_all(
      from(ut in Accounts.UserToken, where: ut.token == ^token),
      set: [inserted_at: dt, authenticated_at: dt]
    )
  end

  defp maybe_set_locale(attrs) when is_map(attrs) do
    Map.put_new(attrs, :locale, @default_locale)
  end

  defp maybe_set_locale(attrs) when is_list(attrs) do
    Keyword.put_new(attrs, :locale, @default_locale)
  end

  @spec employer_user_fixture(attrs()) :: User.t()
  def employer_user_fixture(attrs \\ [locale: "en"]) do
    attrs =
      case attrs do
        attrs when is_map(attrs) -> Map.put(attrs, :user_type, :employer)
        attrs when is_list(attrs) -> Keyword.put(attrs, :user_type, :employer)
      end

    user_fixture(attrs)
  end
end
