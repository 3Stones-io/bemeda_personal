defmodule BemedaPersonal.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.Accounts` context.
  """

  import Ecto.Query

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Accounts.User

  @type attrs :: map() | keyword()

  @default_locale Application.compile_env!(:bemeda_personal, BemedaPersonalWeb.Gettext)[
                    :default_locale
                  ]

  @spec unique_user_email() :: String.t()
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  @spec valid_user_password() :: String.t()
  def valid_user_password, do: "securepassword123"

  @spec valid_user_attributes(attrs()) :: map()
  def valid_user_attributes(attrs \\ []) do
    Enum.into(
      attrs,
      %{
        email: unique_user_email(),
        user_type: :job_seeker
      }
    )
  end

  @user_profile_fields [
    :city,
    :country,
    :street,
    :zip_code,
    :department,
    :medical_role,
    :first_name,
    :last_name,
    :gender,
    :phone
  ]

  defp user_with_profile(user, attrs) do
    profile_attrs =
      attrs
      |> Enum.filter(fn {key, _value} -> key in @user_profile_fields end)
      |> Enum.into(%{})

    default_profile = get_default_profile_for_user_type(user.user_type)
    complete_profile = Map.merge(default_profile, profile_attrs)

    {:ok, user} = Accounts.update_user_personal_info(user, complete_profile)
    user
  end

  defp get_default_profile_for_user_type(:employer) do
    %{
      first_name: "John",
      last_name: "Doe",
      gender: "male",
      city: "Berlin",
      country: "Germany",
      street: "123 Main St",
      zip_code: "12345"
    }
  end

  defp get_default_profile_for_user_type(_user_type) do
    %{
      first_name: "John",
      last_name: "Doe",
      gender: :male,
      medical_role: :"Registered Nurse (AKP/DNII/HF/FH)",
      department: :"Intensive Care",
      city: "Berlin",
      country: "Germany",
      street: "123 Main St",
      zip_code: "12345"
    }
  end

  @spec unconfirmed_user_fixture(attrs()) :: User.t()
  def unconfirmed_user_fixture(attrs \\ %{}) do
    # Include profile fields in the initial user creation to avoid empty names in welcome emails
    profile_attrs =
      attrs
      |> Enum.filter(fn {key, _value} -> key in @user_profile_fields end)
      |> Enum.into(%{})

    {:ok, user} =
      attrs
      |> maybe_set_locale()
      |> valid_user_attributes()
      |> Map.merge(profile_attrs)
      |> Accounts.register_user()

    user
  end

  @spec user_fixture(attrs()) :: User.t()
  def user_fixture(attrs \\ %{locale: "en"}) do
    unconfirmed_user = unconfirmed_user_fixture(attrs)

    token =
      extract_user_token(fn url ->
        Accounts.deliver_login_instructions(unconfirmed_user, url)
      end)

    {:ok, {user, _expired_tokens}} =
      Accounts.login_user_by_magic_link(token)

    user_with_profile(user, attrs)
  end

  @spec user_scope_fixture() :: Scope.t()
  def user_scope_fixture do
    user = user_fixture()
    user_scope_fixture(user)
  end

  defp user_scope_fixture(user) do
    Scope.for_user(user)
  end

  @spec set_password(User.t()) :: User.t()
  def set_password(user) do
    password = valid_user_password()

    {:ok, {user, _expired_tokens}} =
      Accounts.update_user_password(user, %{password: password})

    user
  end

  @spec employer_user_fixture(attrs()) :: User.t()
  def employer_user_fixture(attrs \\ %{locale: "en"}) do
    attrs =
      case attrs do
        attrs when is_map(attrs) -> Map.put(attrs, :user_type, :employer)
        attrs when is_list(attrs) -> Keyword.put(attrs, :user_type, :employer)
      end

    user_fixture(attrs)
  end

  @spec extract_user_token(function()) :: String.t()
  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_start, token | _end] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  @spec override_token_authenticated_at(binary(), DateTime.t()) :: :ok
  def override_token_authenticated_at(token, authenticated_at) when is_binary(token) do
    query = from(t in Accounts.UserToken, where: t.token == ^token)

    BemedaPersonal.Repo.update_all(
      query,
      set: [authenticated_at: authenticated_at]
    )
  end

  @spec generate_user_magic_link_token(User.t()) :: {binary(), binary()}
  def generate_user_magic_link_token(user) do
    {encoded_token, user_token} = Accounts.UserToken.build_email_token(user, "login")
    BemedaPersonal.Repo.insert!(user_token)
    {encoded_token, user_token.token}
  end

  @spec offset_user_token(binary(), integer(), System.time_unit()) :: :ok
  def offset_user_token(token, amount_to_add, unit) do
    dt =
      :second
      |> DateTime.utc_now()
      |> DateTime.add(amount_to_add, unit)

    query = from(ut in Accounts.UserToken, where: ut.token == ^token)

    BemedaPersonal.Repo.update_all(
      query,
      set: [inserted_at: dt, authenticated_at: dt]
    )
  end

  defp maybe_set_locale(attrs) when is_map(attrs) do
    Map.put_new(attrs, :locale, @default_locale)
  end

  defp maybe_set_locale(attrs) when is_list(attrs) do
    Keyword.put_new(attrs, :locale, @default_locale)
  end
end
