defmodule BemedaPersonal.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Accounts.UserNotifier
  alias BemedaPersonal.Accounts.UserToken
  alias BemedaPersonal.MediaDataUtils
  alias BemedaPersonal.Repo
  alias Ecto.Multi

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type email :: String.t()
  @type id :: binary()
  @type opts :: keyword()
  @type password :: String.t()
  @type scope :: Scope.t()
  @type token :: binary()
  @type token_struct :: UserToken.t()
  @type user :: User.t()

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  @spec get_user_by_email(email()) :: user() | nil
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  @spec get_user_by_email_and_password(email(), password()) :: user() | nil
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_user!(id()) :: user() | no_return()
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec register_user(attrs()) :: {:ok, user()} | {:error, changeset()}
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @spec change_user_registration(User.t(), map(), keyword()) :: Ecto.Changeset.t()
  def change_user_registration(user, attrs \\ %{}, opts \\ []) do
    User.registration_changeset(user, attrs, opts)
  end

  @doc """
  Invites a user by creating their account and company, then sending login instructions.

  The user will be created with the provided attributes (typically as an employer),
  their company will be created, and they will receive an email with a magic link
  to log in.

  The attrs map should contain both user fields and company fields. Company fields
  should be nested under the "company" key.

  ## Examples

      iex> invite_user(
      ...>   %{email: "user@example.com", first_name: "John", company: %{name: "Company Inc"}},
      ...>   &url/1
      ...> )
      {:ok, %User{}}

      iex> invite_user(%{email: "invalid", company: %{}}, &url/1)
      {:error, %Ecto.Changeset{}}

  """
  @spec invite_user(attrs(), function()) :: {:ok, user()} | {:error, changeset()}
  def invite_user(attrs, magic_link_url_fun) when is_function(magic_link_url_fun, 1) do
    {company_attrs, user_attrs} = Map.pop(attrs, "company", %{})

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:user, User.registration_changeset(%User{}, user_attrs))
      |> Ecto.Multi.run(:company, fn _repo, %{user: user} ->
        create_company_for_user(user, company_attrs)
      end)
      |> Ecto.Multi.run(:email, fn _repo, %{user: user} ->
        deliver_login_instructions(user, magic_link_url_fun)
      end)

    multi
    |> Repo.transaction()
    |> handle_invite_transaction_result()
  end

  defp handle_invite_transaction_result(result) do
    case result do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, _failed_operation, changeset, _changes} -> {:error, changeset}
    end
  end

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  @spec sudo_mode?(user(), integer()) :: boolean()
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    now = DateTime.utc_now()
    ago = DateTime.add(now, minutes, :minute)
    DateTime.after?(ts, ago)
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `BemedaPersonal.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  @spec change_user_email(user(), attrs(), opts()) :: changeset()
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  @spec update_user_email(user(), token()) :: {:ok, user()} | {:error, :transaction_aborted}
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _error -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Updates the user locale preference.

  ## Examples

      iex> update_user_locale(user, %{locale: "de"})
      {:ok, %User{}}

      iex> update_user_locale(user, %{locale: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_user_locale(user(), attrs()) :: {:ok, user()} | {:error, changeset()}
  def update_user_locale(user, attrs) do
    user
    |> User.locale_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `BemedaPersonal.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  @spec change_user_password(user(), attrs(), opts()) :: changeset()
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_user_password(user(), attrs()) ::
          {:ok, {user(), list(token())}} | {:error, changeset()}
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  @spec generate_user_session_token(user()) :: token()
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  @spec get_user_by_session_token(token()) :: {user(), DateTime.t()} | nil
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the user with the given magic link token.
  """
  @spec get_user_by_magic_link_token(token()) :: user() | nil
  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "login"),
         {user, _token} <- Repo.one(query) do
      user
    else
      _error -> nil
    end
  end

  @doc """
  Logs the user in by magic link.

  There are three cases to consider:

  1. The user has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The user has not confirmed their email and no password is set.
     In this case, the user gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The user has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  @spec login_user_by_magic_link(token()) ::
          {:ok, {user(), list(token_struct())}} | {:error, :not_found}
  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_email_token_query(token, "login")

    case Repo.one(query) do
      # Prevent session fixation attacks by disallowing magic links for unconfirmed users with password
      {%User{confirmed_at: nil, hashed_password: hash}, _token} when is_binary(hash) ->
        raise """
        magic link log in is not allowed for unconfirmed users with a password set!

        This cannot happen with the default implementation, which indicates that you
        might have adapted the code to a different use case. Please make sure to read the
        "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
        """

      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(
      ...>   user,
      ...>   current_email,
      ...>   &url(~p"/users/settings/confirm-email/#{&1}")
      ...> )
      {:ok, %{to: ..., body: ...}}

  """
  @spec deliver_user_update_email_instructions(user(), email(), function()) ::
          {:ok, any()} | {:error, any()}
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Delivers the magic link login instructions to the given user.
  """
  @spec deliver_login_instructions(user(), function()) :: {:ok, any()} | {:error, any()}
  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  @spec delete_user_session_token(token()) :: :ok
  def delete_user_session_token(token) do
    query =
      from(t in UserToken, where: t.token == ^token and t.context == "session")

    Repo.delete_all(query)
    :ok
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        query =
          from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id))

        Repo.delete_all(query)

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end

  defp create_company_for_user(user, company_attrs) do
    scope = Scope.for_user(user)
    BemedaPersonal.Companies.create_company(scope, company_attrs)
  end

  @doc """
  A user changeset for updating the user profile.
  """
  @spec change_user_profile(user(), attrs()) :: changeset()
  def change_user_profile(user, attrs \\ %{}) do
    User.user_profile_changeset(user, attrs)
  end

  @doc """
  A user changeset for updating the user employment type.
  """
  @spec change_user_employment_type(user(), attrs()) :: changeset()
  def change_user_employment_type(user, attrs \\ %{}) do
    User.employment_type_changeset(user, attrs)
  end

  @doc """
  A user changeset for updating the user medical role.
  """
  @spec change_user_medical_role(user(), attrs()) :: changeset()
  def change_user_medical_role(user, attrs \\ %{}) do
    User.medical_role_changeset(user, attrs)
  end

  @doc """
  A user changeset for updating the user bio.
  """
  @spec change_user_bio(user(), attrs()) :: changeset()
  def change_user_bio(user, attrs \\ %{}) do
    User.bio_changeset(user, attrs)
  end

  @doc """
  Updates the user profile.
  """
  @spec update_user_profile(user(), function(), attrs()) :: {:ok, user()} | {:error, changeset()}
  def update_user_profile(user, changeset_fun, attrs) do
    user = Repo.preload(user, [:media_asset])
    changeset = changeset_fun.(user, attrs)

    multi =
      Multi.new()
      |> Multi.update(:user, changeset)
      |> Multi.run(:media_asset, fn repo, %{user: updated_user} ->
        MediaDataUtils.handle_media_asset(repo, user.media_asset, updated_user, attrs)
      end)

    case Repo.transaction(multi) do
      {:ok, %{user: updated_user}} ->
        updated_user = Repo.preload(updated_user, [:media_asset], force: true)
        {:ok, updated_user}

      {:error, _operation, changeset, _changes} ->
        {:error, changeset}
    end
  end
end
