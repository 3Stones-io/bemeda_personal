defmodule BemedaPersonal.Accounts.User do
  @moduledoc false

  use Ecto.Schema
  use Gettext, backend: BemedaPersonalWeb.Gettext

  import Ecto.Changeset

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type opts :: keyword()
  @type password :: String.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :city, :string
    field :confirmed_at, :utc_datetime
    field :country, :string
    field :current_password, :string, virtual: true, redact: true
    field :email, :string
    field :first_name, :string
    field :gender, :string
    field :hashed_password, :string, redact: true
    field :last_name, :string
    field :line1, :string
    field :line2, :string
    field :locale, Ecto.Enum, values: [:de, :en, :fr, :it], default: :de
    field :password, :string, virtual: true, redact: true
    field :title, :string
    field :zip_code, :string

    has_one :resume, BemedaPersonal.Resumes.Resume

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  @spec registration_changeset(t() | changeset(), attrs(), opts()) :: changeset()
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [
      :city,
      :country,
      :email,
      :first_name,
      :gender,
      :last_name,
      :line1,
      :line2,
      :locale,
      :password,
      :title,
      :zip_code
    ])
    |> validate_email(opts)
    |> validate_password(opts)
    |> validate_name()
    |> validate_required([:city, :country, :line1, :zip_code])
    |> validate_length(:city, min: 1, max: 100)
    |> validate_length(:country, min: 1, max: 100)
    |> validate_length(:gender, max: 50)
    |> validate_length(:line1, min: 1, max: 255)
    |> validate_length(:line2, max: 255)
    |> validate_length(:title, max: 100)
    |> validate_length(:zip_code, min: 1, max: 20)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/,
      message: dgettext("auth", "must have the @ sign and no spaces")
    )
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
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

  defp validate_name(changeset) do
    changeset
    |> validate_required([:first_name, :last_name])
    |> validate_length(:first_name, min: 1, max: 255)
    |> validate_length(:last_name, min: 1, max: 255)
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

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, BemedaPersonal.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  @spec email_changeset(t() | changeset(), attrs(), opts()) :: changeset()
  def email_changeset(user, attrs, opts \\ []) do
    changeset =
      user
      |> cast(attrs, [:email])
      |> validate_email(opts)

    case changeset do
      %{changes: %{email: _email}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, dgettext("auth", "did not change"))
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  @spec password_changeset(t() | changeset(), attrs(), opts()) :: changeset()
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password,
      message: dgettext("auth", "does not match password")
    )
    |> validate_password(opts)
  end

  @doc """
  A user changeset for updating the locale preference.
  """
  @spec locale_changeset(t() | changeset(), attrs()) :: changeset()
  def locale_changeset(user, attrs) do
    user
    |> cast(attrs, [:locale])
    |> validate_required([:locale])
  end

  @doc """
  A user changeset for updating personal info fields.
  """
  @spec personal_info_changeset(t() | changeset(), attrs()) :: changeset()
  def personal_info_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :city,
      :country,
      :first_name,
      :gender,
      :last_name,
      :line1,
      :line2,
      :title,
      :zip_code
    ])
    |> validate_required([:city, :country, :first_name, :last_name, :line1, :zip_code])
    |> validate_length(:city, min: 1, max: 100)
    |> validate_length(:country, min: 1, max: 100)
    |> validate_length(:first_name, min: 1, max: 160)
    |> validate_length(:gender, max: 50)
    |> validate_length(:last_name, min: 1, max: 160)
    |> validate_length(:line1, min: 1, max: 255)
    |> validate_length(:line2, max: 255)
    |> validate_length(:title, max: 100)
    |> validate_length(:zip_code, min: 1, max: 20)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  @spec confirm_changeset(t() | changeset()) :: changeset()
  def confirm_changeset(user) do
    now = DateTime.utc_now(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  @spec valid_password?(t(), password()) :: boolean()
  def valid_password?(%BemedaPersonal.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_user, _password) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  @spec validate_current_password(changeset(), password()) :: changeset()
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, dgettext("auth", "is not valid"))
    end
  end
end
