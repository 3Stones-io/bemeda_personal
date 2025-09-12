defmodule BemedaPersonal.Accounts.User do
  use Ecto.Schema
  use Gettext, backend: BemedaPersonalWeb.Gettext

  import Ecto.Changeset

  alias BemedaPersonal.Accounts.Address
  alias BemedaPersonal.Resumes.Resume
  alias BemedaPersonal.Accounts.UserProfile
  alias BemedaPersonal.Accounts.WorkProfile

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type opts :: keyword()
  @type password :: String.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    embeds_one :address, Address, on_replace: :update
    field :authenticated_at, :utc_datetime, virtual: true
    field :confirmed_at, :utc_datetime
    field :current_password, :string, virtual: true, redact: true
    field :email, :string
    field :hashed_password, :string, redact: true
    field :locale, Ecto.Enum, values: [:de, :en, :fr, :it], default: :de
    field :password, :string, virtual: true, redact: true
    embeds_one :profile, UserProfile, on_replace: :update
    has_one :resume, Resume
    field :user_type, Ecto.Enum, values: [:job_seeker, :employer], default: :job_seeker
    embeds_one :work_profile, WorkProfile, on_replace: :update

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registering or changing the email.

  It requires the email to change otherwise an error is added.

  ## Options

    * `:validate_unique` - Set to false if you don't want to validate the
      uniqueness of the email, useful when displaying live validations.
      Defaults to `true`.
  """
  @spec email_changeset(t(), attrs(), opts()) :: changeset()
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :locale, :user_type])
    |> validate_email(opts)
    |> cast_embed(:profile)
    |> cast_embed(:address)
    |> cast_embed(:work_profile)
  end

  defp validate_email(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: dgettext("auth", "must have the @ sign and no spaces")
      )
      |> validate_length(:email, max: 160)

    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:email, BemedaPersonal.Repo)
      |> unique_constraint(:email)
      |> validate_email_changed()
    else
      changeset
    end
  end

  defp validate_email_changed(changeset) do
    if get_field(changeset, :email) && get_change(changeset, :email) == nil do
      add_error(changeset, :email, dgettext("auth", "did not change"))
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the password.

  It is important to validate the length of the password, as long passwords may
  be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  @spec password_changeset(t(), attrs(), opts()) :: changeset()
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: dgettext("auth", "does not match password"))
    |> validate_password(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  @spec confirm_changeset(t()) :: changeset()
  def confirm_changeset(user) do
    now = DateTime.utc_now(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  @spec valid_password?(t(), password :: String.t()) :: boolean()
  def valid_password?(%__MODULE__{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_user, _password) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  A user changeset for changing the locale.
  """
  @spec locale_changeset(t(), attrs()) :: changeset()
  def locale_changeset(user, attrs) do
    user
    |> cast(attrs, [:locale])
    |> validate_inclusion(:locale, [:de, :en, :fr, :it])
  end

  @doc """
  A user changeset for changing the profile.
  """
  @spec profile_changeset(t(), attrs()) :: changeset()
  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [])
    |> cast_embed(:profile)
    |> cast_embed(:address)
    |> cast_embed(:work_profile)
  end
end
