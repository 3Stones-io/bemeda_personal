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

  @type attrs :: map() | keyword()
  @type scope :: Scope.t()
  @type user :: User.t()

  @default_locale Application.compile_env!(:bemeda_personal, BemedaPersonalWeb.Gettext)[
                    :default_locale
                  ]

  @spec unique_user_email() :: String.t()
  def unique_user_email do
    # Use microsecond timestamp + unique integers + random string for guaranteed uniqueness
    # even in shared database mode with BDD tests
    timestamp = System.system_time(:microsecond)
    unique1 = System.unique_integer([:positive])
    unique2 = :erlang.unique_integer([:positive])
    random_bytes = :crypto.strong_rand_bytes(8)
    random = Base.encode16(random_bytes, case: :lower)

    "user#{timestamp}_#{unique1}_#{unique2}_#{random}@example.com"
  end

  @spec valid_user_password() :: String.t()
  def valid_user_password, do: "securepassword123"

  @spec valid_user_attributes(attrs()) :: map()
  def valid_user_attributes(attrs \\ %{}) do
    attrs_map = Enum.into(attrs, %{})

    user_attrs = %{
      email: unique_user_email(),
      first_name: "Test",
      last_name: "User"
    }

    Map.merge(user_attrs, attrs_map)
  end

  @spec unconfirmed_user_fixture(attrs()) :: user()
  def unconfirmed_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> maybe_set_locale()
      |> Accounts.register_user()

    user
  end

  @spec user_fixture(attrs()) :: user()
  def user_fixture(attrs \\ %{}) do
    unconfirmed_user = unconfirmed_user_fixture(attrs)

    token =
      extract_user_token(fn url ->
        Accounts.deliver_login_instructions(unconfirmed_user, url)
      end)

    {:ok, {user, _expired_tokens}} =
      Accounts.login_user_by_magic_link(token)

    # Convert attrs to map for easy access
    attrs_map = Enum.into(attrs, %{})

    user_with_address =
      if Map.has_key?(attrs_map, :city) or Map.has_key?(attrs_map, :street) or
           Map.has_key?(attrs_map, :zip_code) or Map.has_key?(attrs_map, :gender) do
        address_attrs =
          %{}
          |> maybe_put(:city, Map.get(attrs_map, :city))
          |> maybe_put(:street, Map.get(attrs_map, :street))
          |> maybe_put(:zip_code, Map.get(attrs_map, :zip_code))
          |> maybe_put(:gender, Map.get(attrs_map, :gender))

        changeset = Ecto.Changeset.cast(user, address_attrs, [:city, :street, :zip_code, :gender])

        case BemedaPersonal.Repo.update(changeset) do
          {:ok, updated_user} -> updated_user
          {:error, _changeset} -> user
        end
      else
        user
      end

    complete_user =
      if user_with_address.user_type == :job_seeker do
        profile_attrs = %{
          medical_role: Map.get(attrs_map, :medical_role, "Physiotherapist"),
          employment_type: Map.get(attrs_map, :employment_type, ["Full-time Hire"]),
          location: Map.get(attrs_map, :location, "Zurich"),
          bio: Map.get(attrs_map, :bio, "Experienced healthcare professional")
        }

        {:ok, user_with_profile} =
          Accounts.update_user_profile(
            user_with_address,
            &Accounts.change_user_profile/2,
            profile_attrs
          )

        user_with_profile
      else
        user_with_address
      end

    complete_user
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  @spec employer_user_fixture(attrs()) :: user()
  def employer_user_fixture(attrs \\ [locale: "en"]) do
    attrs =
      case attrs do
        attrs when is_map(attrs) -> Map.put(attrs, :user_type, :employer)
        attrs when is_list(attrs) -> Keyword.put(attrs, :user_type, :employer)
      end

    user_fixture(attrs)
  end

  @spec user_scope_fixture() :: scope()
  def user_scope_fixture do
    user = user_fixture()
    user_scope_fixture(user)
  end

  @spec user_scope_fixture(user()) :: scope()
  def user_scope_fixture(user) do
    Scope.for_user(user)
  end

  @spec employer_scope_fixture(attrs()) :: scope()
  def employer_scope_fixture(attrs \\ []) do
    user = user_fixture(Keyword.put(attrs, :user_type, :employer))
    company = BemedaPersonal.CompaniesFixtures.company_fixture(user)

    scope = Scope.for_user(user)
    Scope.put_company(scope, company)
  end

  @spec job_seeker_scope_fixture(attrs()) :: scope()
  def job_seeker_scope_fixture(attrs \\ []) do
    user = user_fixture(Keyword.put(attrs, :user_type, :job_seeker))
    Scope.for_user(user)
  end

  @spec job_seeker_user_fixture() :: User.t()
  def job_seeker_user_fixture do
    user_fixture(user_type: :job_seeker)
  end

  @spec set_password(user()) :: user()
  def set_password(user) do
    {:ok, {user, _expired_tokens}} =
      Accounts.update_user_password(user, %{password: valid_user_password()})

    user
  end

  @spec override_token_authenticated_at(binary(), DateTime.t()) :: {integer(), nil}
  def override_token_authenticated_at(token, authenticated_at) when is_binary(token) do
    query = from(t in Accounts.UserToken, where: t.token == ^token)

    Repo.update_all(
      query,
      set: [authenticated_at: authenticated_at]
    )
  end

  @spec generate_user_magic_link_token(user()) :: {binary(), binary()}
  def generate_user_magic_link_token(user) do
    {encoded_token, user_token} = Accounts.UserToken.build_email_token(user, "login")

    Repo.insert!(user_token)

    {encoded_token, user_token.token}
  end

  @spec offset_user_token(binary(), integer(), System.time_unit()) :: :ok
  def offset_user_token(token, amount_to_add, unit) do
    dt =
      :second
      |> DateTime.utc_now()
      |> DateTime.add(amount_to_add, unit)

    query = from(ut in Accounts.UserToken, where: ut.token == ^token)

    Repo.update_all(
      query,
      set: [inserted_at: dt, authenticated_at: dt]
    )
  end

  @spec extract_user_token(function()) :: String.t()
  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_start, token | _end] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  defp maybe_set_locale(attrs) when is_map(attrs) do
    Map.put_new(attrs, :locale, @default_locale)
  end
end
