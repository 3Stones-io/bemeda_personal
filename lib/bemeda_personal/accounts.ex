defmodule BemedaPersonal.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Changeset, only: [change: 2]
  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts.MagicLinkToken
  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Accounts.UserNotifier
  alias BemedaPersonal.Accounts.UserToken
  alias BemedaPersonal.Repo

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type email :: String.t()
  @type id :: binary()
  @type password :: String.t()
  @type scope :: Scope.t()
  @type token :: String.t()
  @type user :: User.t()

  ## Database getters

  @doc """
  Gets a user by email with scope filtering.

  ## Examples

      iex> get_user_by_email(scope, "foo@example.com")
      %User{}

      iex> get_user_by_email(scope, "unknown@example.com")
      nil

      iex> get_user_by_email(nil, "foo@example.com")
      nil

  """
  @spec get_user_by_email(scope() | nil, email()) :: user() | nil
  def get_user_by_email(%Scope{} = _scope, email) when is_binary(email) do
    # For now, scope-aware version works the same as regular version
    # In the future, this could filter by scope permissions
    Repo.get_by(User, email: email)
  end

  def get_user_by_email(nil, email) when is_binary(email) do
    # Allow unauthenticated access for login/registration flows
    Repo.get_by(User, email: email)
  end

  def get_user_by_email(nil, _email), do: nil

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
  @spec get_user!(id()) :: user()
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a single user with scope filtering.

  Raises `Ecto.NoResultsError` if the User does not exist or scope is nil.

  ## Examples

      iex> get_user!(scope, 123)
      %User{}

      iex> get_user!(scope, 456)
      ** (Ecto.NoResultsError)

      iex> get_user!(nil, 123)
      ** (Ecto.NoResultsError)

  """
  @spec get_user!(scope() | nil, id()) :: user()
  def get_user!(%Scope{} = _scope, id) do
    # For now, scope-aware version works the same as regular version
    # In the future, this could filter by scope permissions
    Repo.get!(User, id)
  end

  def get_user!(nil, _id) do
    raise Ecto.NoResultsError, queryable: User
  end

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

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  @spec change_user_registration(user(), attrs()) :: changeset()
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for Step 1 of user registration (basic information).

  This changeset validates only the fields relevant to Step 1:
  - email, first_name, last_name, password

  ## Examples

      iex> change_user_registration_step1(%User{})
      %Ecto.Changeset{data: %User{}}

  """
  @spec change_user_registration_step1(user(), attrs()) :: changeset()
  def change_user_registration_step1(%User{} = user, attrs \\ %{}) do
    User.registration_step1_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for Step 2 of user registration (personal information).

  This changeset validates only the fields relevant to Step 2:
  - gender, street, zip_code, city, country

  ## Examples

      iex> change_user_registration_step2(%User{})
      %Ecto.Changeset{data: %User{}}

  """
  @spec change_user_registration_step2(user(), attrs()) :: changeset()
  def change_user_registration_step2(%User{} = user, attrs \\ %{}) do
    User.registration_step2_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  @spec change_user_email(user(), attrs()) :: changeset()
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  @spec apply_user_email(user(), password(), attrs()) :: {:ok, user()} | {:error, changeset()}
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  @spec update_user_email(user(), token()) :: :ok | :error
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         multi <- user_email_multi(user, email, context),
         {:ok, %{user: _user}} <- Repo.transaction(multi) do
      :ok
    else
      {:error, :token_verification_failed} -> :error
      {:error, :user_not_found} -> :error
      {:error, :transaction_failed} -> :error
      _other -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(
      ...>   user,
      ...>   current_email,
      ...>   &url(~p"/users/settings/confirm_email/#{&1}")
      ...> )
      {:ok, %{to: ..., body: ...}}

  """
  @spec deliver_user_update_email_instructions(user(), email(), function()) ::
          {:ok, map()} | {:error, any()}
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  @spec change_user_password(user(), attrs()) :: changeset()
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_user_password(user(), password(), attrs()) :: {:ok, user()} | {:error, changeset()}
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.update(:user, changeset)
      |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
      |> Repo.transaction()

    case result do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _changes_so_far} -> {:error, changeset}
    end
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
  """
  @spec get_user_by_session_token(token()) :: user() | nil
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  @spec delete_user_session_token(token()) :: :ok
  def delete_user_session_token(token) do
    token
    |> UserToken.by_token_and_context_query("session")
    |> Repo.delete_all()

    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  @spec deliver_user_confirmation_instructions(user(), function()) ::
          {:ok, map()} | {:error, any()}
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  @spec confirm_user(token()) :: {:ok, user()} | :error
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         multi <- confirm_user_multi(user),
         {:ok, %{user: user}} <- Repo.transaction(multi) do
      {:ok, user}
    else
      {:error, :token_verification_failed} -> :error
      {:error, :user_not_found} -> :error
      {:error, :transaction_failed} -> :error
      _other -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  @spec deliver_user_reset_password_instructions(user(), function()) ::
          {:ok, map()} | {:error, any()}
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  @spec get_user_by_reset_password_token(token()) :: user() | nil
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      {:error, :token_verification_failed} -> nil
      {:error, :user_not_found} -> nil
      _other -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{
      ...>   password: "new long password",
      ...>   password_confirmation: "new long password"
      ...> })
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  @spec reset_user_password(user(), attrs()) :: {:ok, user()} | {:error, changeset()}
  def reset_user_password(user, attrs) do
    result =
      Ecto.Multi.new()
      |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
      |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
      |> Repo.transaction()

    case result do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _changes_so_far} -> {:error, changeset}
    end
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
  Returns an `%Ecto.Changeset{}` for changing the user personal info.

  ## Examples

      iex> change_user_personal_info(user)
      %Ecto.Changeset{data: %User{}}

  """
  @spec change_user_personal_info(user(), attrs()) :: changeset()
  def change_user_personal_info(%User{} = user, attrs \\ %{}) do
    User.personal_info_changeset(user, attrs)
  end

  @doc """
  Updates the user personal info.

  ## Examples

      iex> update_user_personal_info(user, %{gender: "female", title: "Dr."})
      {:ok, %User{}}

      iex> update_user_personal_info(user, %{title: "invalid_long_title"})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_user_personal_info(user(), attrs()) :: {:ok, user()} | {:error, changeset()}
  def update_user_personal_info(%User{} = user, attrs) do
    user
    |> User.personal_info_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates the user personal info with scope authorization.

  ## Examples

      iex> update_user_personal_info(scope, user, %{gender: "female", title: "Dr."})
      {:ok, %User{}}

      iex> update_user_personal_info(nil, user, %{title: "Dr."})
      {:error, :unauthorized}

      iex> update_user_personal_info(other_scope, user, %{title: "Dr."})
      {:error, :unauthorized}

  """
  @spec update_user_personal_info(scope() | nil, user(), attrs()) ::
          {:ok, user()} | {:error, changeset() | :unauthorized}
  def update_user_personal_info(
        %Scope{user: %User{id: scope_user_id}},
        %User{id: target_user_id} = user,
        attrs
      )
      when scope_user_id == target_user_id do
    user
    |> User.personal_info_changeset(attrs)
    |> Repo.update()
  end

  def update_user_personal_info(_scope, _user, _attrs) do
    {:error, :unauthorized}
  end

  ## Magic Link Functions

  @doc """
  Generates and sends a magic link to the user's email
  """
  @spec deliver_magic_link(User.t(), function()) ::
          {:ok, MagicLinkToken.t()} | {:error, :too_many_requests | :magic_links_disabled}
  def deliver_magic_link(%User{magic_link_enabled: false}, _magic_link_url_fun) do
    {:error, :magic_links_disabled}
  end

  def deliver_magic_link(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    # Rate limiting: max 3 magic links per hour
    one_hour_ago = DateTime.add(DateTime.utc_now(), -3600, :second)

    query =
      from(t in MagicLinkToken,
        where: t.user_id == ^user.id,
        where: t.inserted_at > ^one_hour_ago,
        select: count(t.id)
      )

    recent_count = Repo.one(query)

    if recent_count >= 3 do
      {:error, :too_many_requests}
    else
      token = MagicLinkToken.build_magic_link_token(user, "magic_link")

      Repo.transaction(fn ->
        {:ok, inserted_token} = Repo.insert(token)
        {:ok, _user} = User.track_magic_link_sent(user)

        UserNotifier.deliver_magic_link(
          user,
          magic_link_url_fun.(Base.url_encode64(inserted_token.token, padding: false))
        )

        inserted_token
      end)
    end
  end

  @doc """
  Verifies a magic link token and logs the user in
  """
  @spec verify_magic_link(String.t() | nil) :: {:ok, User.t()} | {:error, :invalid_or_expired}
  def verify_magic_link(nil), do: {:error, :invalid_or_expired}

  def verify_magic_link(token_string) when is_binary(token_string) do
    with {:ok, token} <- Base.url_decode64(token_string, padding: false),
         %MagicLinkToken{} = magic_token <- get_valid_magic_link_token(token),
         {:ok, _token} <- MagicLinkToken.mark_as_used(magic_token),
         %User{} = user <- Repo.get(User, magic_token.user_id) do
      {:ok, user}
    else
      _error -> {:error, :invalid_or_expired}
    end
  end

  defp get_valid_magic_link_token(token) do
    query =
      from t in MagicLinkToken,
        join: u in assoc(t, :user),
        where: t.token == ^token,
        where: t.context == "magic_link",
        where: is_nil(t.used_at),
        where: t.inserted_at > ago(15, "minute"),
        preload: [user: u]

    Repo.one(query)
  end

  @doc """
  Delivers sudo mode magic link for sensitive operations
  """
  @spec deliver_sudo_magic_link(User.t(), function()) :: {:ok, MagicLinkToken.t()}
  def deliver_sudo_magic_link(%User{} = user, sudo_url_fun) when is_function(sudo_url_fun, 1) do
    token = MagicLinkToken.build_magic_link_token(user, "sudo")

    Repo.transaction(fn ->
      {:ok, inserted_token} = Repo.insert(token)

      UserNotifier.deliver_sudo_link(
        user,
        sudo_url_fun.(Base.url_encode64(inserted_token.token, padding: false))
      )

      inserted_token
    end)
  end

  @doc """
  Verifies sudo mode access
  """
  @spec verify_sudo_token(String.t()) :: {:ok, User.t()} | {:error, :invalid_or_expired}
  def verify_sudo_token(token_string) do
    with {:ok, token} <- Base.url_decode64(token_string, padding: false),
         %MagicLinkToken{} = magic_token <- get_valid_sudo_token(token),
         {:ok, _token} <- MagicLinkToken.mark_as_used(magic_token),
         %User{} = user <- Repo.get(User, magic_token.user_id),
         {:ok, updated_user} <- User.record_sudo_authentication(user) do
      {:ok, updated_user}
    else
      _error -> {:error, :invalid_or_expired}
    end
  end

  defp get_valid_sudo_token(token) do
    query =
      from t in MagicLinkToken,
        where: t.token == ^token,
        where: t.context == "sudo",
        where: is_nil(t.used_at),
        where: t.inserted_at > ago(5, "minute")

    Repo.one(query)
  end

  @doc """
  Checks if user has recent sudo authentication
  """
  @spec has_recent_sudo?(User.t() | nil) :: boolean()
  def has_recent_sudo?(nil), do: false
  def has_recent_sudo?(%User{last_sudo_at: nil}), do: false

  def has_recent_sudo?(%User{last_sudo_at: last_sudo}) do
    # 15 minutes
    minutes_ago = DateTime.add(DateTime.utc_now(), -900, :second)
    DateTime.compare(last_sudo, minutes_ago) == :gt
  end

  @doc """
  Updates user's magic link preferences
  """
  @spec update_magic_link_preferences(User.t(), map()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_magic_link_preferences(%User{} = user, attrs) do
    user
    |> User.magic_link_preferences_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates the user's sudo timestamp to current time
  """
  @spec update_user_sudo_timestamp(User.t()) :: {:ok, User.t()} | {:error, changeset()}
  def update_user_sudo_timestamp(%User{} = user) do
    user
    |> change(%{last_sudo_at: DateTime.utc_now(:second)})
    |> Repo.update()
  end

  @doc """
  Resets the magic link send count to 0
  """
  @spec reset_magic_link_send_count(User.t()) :: {:ok, User.t()} | {:error, changeset()}
  def reset_magic_link_send_count(%User{} = user) do
    user
    |> change(%{magic_link_send_count: 0})
    |> Repo.update()
  end

  @doc """
  Clears recent magic link tokens for a user (for testing rate limiting)

  This removes all MagicLinkToken records for the user that were created in the past hour,
  effectively resetting the database-based rate limiting. Used in conjunction with
  reset_magic_link_send_count/1 to fully reset rate limiting for testing purposes.
  """
  @spec clear_recent_magic_link_tokens(User.t()) :: :ok
  def clear_recent_magic_link_tokens(%User{} = user) do
    one_hour_ago = DateTime.add(DateTime.utc_now(), -3600, :second)

    query =
      from(t in MagicLinkToken,
        where: t.user_id == ^user.id,
        where: t.inserted_at > ^one_hour_ago
      )

    Repo.delete_all(query)
    :ok
  end

  @doc """
  Lists all users with scope authorization
  """
  @spec list_users(scope()) :: [User.t()]
  def list_users(%Scope{} = _scope) do
    # For now, return all users - in future this could be filtered by scope permissions
    Repo.all(User)
  end
end
