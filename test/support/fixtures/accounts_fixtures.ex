defmodule BemedaPersonal.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.Accounts` context.
  """

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Accounts.User

  @type attrs :: keyword()
  @type scope :: Scope.t()

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
  def valid_user_attributes(attrs \\ []) do
    Enum.into(
      attrs,
      %{
        city: "Test City",
        country: "Test Country",
        department: :"Hospital / Clinic",
        email: unique_user_email(),
        first_name: "Test",
        gender: :male,
        last_name: "User",
        medical_role: :"Registered Nurse (AKP/DNII/HF/FH)",
        password: valid_user_password(),
        street: "123 Test Street",
        user_type: :job_seeker,
        zip_code: "12345"
      }
    )
  end

  @spec user_fixture(attrs()) :: User.t()
  def user_fixture(attrs \\ [locale: "en"]) do
    {:ok, user} =
      attrs
      |> maybe_set_locale()
      |> valid_user_attributes()
      |> BemedaPersonal.Accounts.register_user()

    confirmed_user =
      if attrs[:confirmed] do
        user
        |> Ecto.Changeset.change(%{confirmed_at: DateTime.utc_now(:second)})
        |> BemedaPersonal.Repo.update!()
      else
        user
      end

    # Handle magic link preferences if specified
    magic_link_attrs =
      attrs
      |> Enum.filter(fn {key, _value} -> key in [:magic_link_enabled, :passwordless_only] end)
      |> Enum.into(%{})

    if magic_link_attrs != %{} do
      confirmed_user
      |> User.magic_link_preferences_changeset(magic_link_attrs)
      |> BemedaPersonal.Repo.update!()
    else
      confirmed_user
    end
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

  @spec extract_user_token(function()) :: String.t()
  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_start, token | _end] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  defp maybe_set_locale(attrs) when is_map(attrs) do
    Map.put_new(attrs, :locale, @default_locale)
  end

  defp maybe_set_locale(attrs) when is_list(attrs) do
    Keyword.put_new(attrs, :locale, @default_locale)
  end

  @doc """
  Generate a user scope fixture
  """
  @spec user_scope_fixture(attrs()) :: scope()
  def user_scope_fixture(attrs \\ []) do
    user = user_fixture(attrs)
    Scope.for_user(user)
  end

  @doc """
  Generate an employer scope with company
  """
  @spec employer_scope_fixture(attrs()) :: scope()
  def employer_scope_fixture(attrs \\ []) do
    user = user_fixture(Keyword.put(attrs, :user_type, :employer))
    company = BemedaPersonal.CompaniesFixtures.company_fixture(user)

    scope = Scope.for_user(user)
    Scope.put_company(scope, company)
  end

  @doc """
  Generate a job seeker scope
  """
  @spec job_seeker_scope_fixture(attrs()) :: scope()
  def job_seeker_scope_fixture(attrs \\ []) do
    user = user_fixture(Keyword.put(attrs, :user_type, :job_seeker))
    Scope.for_user(user)
  end

  @doc """
  Generate a job seeker user without any parameters
  """
  @spec job_seeker_user_fixture() :: User.t()
  def job_seeker_user_fixture do
    user_fixture(user_type: :job_seeker)
  end
end
