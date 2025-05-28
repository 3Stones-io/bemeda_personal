defmodule BemedaPersonal.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.Accounts` context.
  """

  alias BemedaPersonal.Accounts.User

  @type attrs :: keyword()

  @default_locale Application.compile_env!(:bemeda_personal, BemedaPersonalWeb.Gettext)[
                    :default_locale
                  ]

  @spec unique_user_email() :: String.t()
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  @spec valid_user_password() :: String.t()
  def valid_user_password, do: "hello world!"

  @spec valid_user_attributes(attrs()) :: map()
  def valid_user_attributes(attrs \\ []) do
    Enum.into(
      attrs,
      %{
        email: unique_user_email(),
        first_name: "Test",
        last_name: "User",
        password: valid_user_password()
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

    if attrs[:confirmed] do
      user
      |> Ecto.Changeset.change(%{confirmed_at: DateTime.utc_now(:second)})
      |> BemedaPersonal.Repo.update!()
    else
      user
    end
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
end
