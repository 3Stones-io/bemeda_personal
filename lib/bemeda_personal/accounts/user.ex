defmodule BemedaPersonal.Accounts.User do
  @moduledoc false

  use Ecto.Schema
  use Gettext, backend: BemedaPersonalWeb.Gettext

  import Ecto.Changeset

  alias BemedaPersonal.JobPostings.Enums
  alias BemedaPersonal.Utils

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type opts :: keyword()
  @type password :: String.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :authenticated_at, :utc_datetime, virtual: true
    field :bio, :string
    field :city, :string
    field :confirmed_at, :utc_datetime
    field :country, :string
    field :date_of_birth, :date
    field :department, Ecto.Enum, values: Enums.departments()
    field :email, :string
    field :employment_type, {:array, Ecto.Enum}, values: Enums.employment_types()
    field :first_name, :string
    field :gender, Ecto.Enum, values: [:male, :female]
    field :hashed_password, :string, redact: true
    field :last_name, :string
    field :locale, Ecto.Enum, values: [:de, :en, :fr, :it], default: :de
    field :location, Ecto.Enum, values: Enums.regions()
    has_one :media_asset, BemedaPersonal.Media.MediaAsset
    field :medical_role, Ecto.Enum, values: Enums.professions()
    field :password, :string, virtual: true, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :phone, :string
    field :registration_source, Ecto.Enum, values: [:email, :invited], default: :email
    has_one :resume, BemedaPersonal.Resumes.Resume
    field :street, :string
    field :user_type, Ecto.Enum, values: [:job_seeker, :employer], default: :job_seeker
    field :zip_code, :string
    field :deleted_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset registering a user.

    ## Options

    * `:validate_unique` - Set to false if you don't want to validate the
      uniqueness of the email, useful when displaying live validations.
      Defaults to `true`.
  """
  @spec registration_changeset(t() | changeset(), attrs(), opts()) :: changeset()
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [
      :email,
      :first_name,
      :last_name,
      :locale,
      :registration_source,
      :user_type
    ])
    |> validate_email(opts)
    |> validate_name()
  end

  @doc """
  A user changeset changing the email.

  It requires the email to change otherwise an error is added.

  ## Options

    * `:validate_unique` - Set to false if you don't want to validate the
      uniqueness of the email, useful when displaying live validations.
      Defaults to `true`.
  """
  @spec email_changeset(t() | changeset(), attrs(), opts()) :: changeset()
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
  end

  defp validate_email(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: "must have the @ sign and no spaces"
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
      add_error(changeset, :email, "did not change")
    else
      changeset
    end
  end

  defp validate_name(changeset) do
    changeset
    |> validate_required([:first_name, :last_name])
    |> validate_length(:first_name, min: 1, max: 255)
    |> validate_length(:last_name, min: 1, max: 255)
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
  @spec password_changeset(t() | changeset(), attrs(), opts()) :: changeset()
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password, :current_password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
    |> maybe_verify_current_password(opts)
  end

  defp maybe_verify_current_password(changeset, opts) do
    if Keyword.get(opts, :verify_current_password, false) do
      verify_current_password(changeset)
    else
      changeset
    end
  end

  defp verify_current_password(changeset) do
    current_password = get_change(changeset, :current_password)

    if current_password_valid?(changeset, current_password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  defp current_password_valid?(_changeset, nil), do: false
  defp current_password_valid?(changeset, password), do: valid_password?(changeset.data, password)

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
  @spec valid_password?(t() | changeset(), password()) :: boolean()
  def valid_password?(%BemedaPersonal.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_user, _password) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Checks if a user has a password set.
  """
  @spec has_password?(t()) :: boolean()
  def has_password?(%__MODULE__{hashed_password: hashed_password})
      when is_binary(hashed_password),
      do: true

  def has_password?(_user), do: false

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
  Returns true if the user is a job seeker.
  """
  @spec job_seeker?(t()) :: boolean()
  def job_seeker?(%__MODULE__{user_type: :job_seeker}), do: true
  def job_seeker?(_user), do: false

  @doc """
  Returns true if the user is an employer.
  """
  @spec employer?(t()) :: boolean()
  def employer?(%__MODULE__{user_type: :employer}), do: true
  def employer?(_user), do: false

  @doc """
  A user changeset for updating the user profile.
  """
  @spec user_profile_changeset(t() | changeset(), attrs()) :: changeset()
  def user_profile_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:medical_role, :department, :employment_type, :location, :bio])
    |> validate_required([:medical_role, :employment_type, :location, :bio])
  end

  @spec update_user_profile_changeset(t() | changeset(), attrs()) :: changeset()
  def update_user_profile_changeset(user, attrs) do
    cast(user, attrs, [:medical_role, :department, :employment_type, :location, :bio])
  end

  @spec employment_type_changeset(t() | changeset(), attrs()) :: changeset()
  def employment_type_changeset(user, attrs) do
    user
    |> cast(attrs, [:employment_type])
    |> validate_required([:employment_type])
  end

  @spec medical_role_changeset(t() | changeset(), attrs()) :: changeset()
  def medical_role_changeset(user, attrs) do
    user
    |> cast(attrs, [:medical_role, :department, :location, :phone])
    |> validate_required([:medical_role, :location, :phone])
    |> Utils.validate_e164_phone_number(:phone)
  end

  @spec bio_changeset(t() | changeset(), attrs()) :: changeset()
  def bio_changeset(user, attrs) do
    user
    |> cast(attrs, [:bio])
    |> validate_required([:bio])
  end

  @spec change_account_information_changeset(t() | changeset(), attrs(), opts()) :: changeset()
  def change_account_information_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [
      :date_of_birth,
      :email,
      :first_name,
      :gender,
      :last_name,
      :location,
      :phone
    ])
    |> validate_email_for_account_info(opts)
    |> validate_name()
  end

  defp validate_email_for_account_info(changeset, opts) do
    email_changed? = get_change(changeset, :email) != nil

    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)

    if email_changed? and Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:email, BemedaPersonal.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @spec full_name(t()) :: String.t()
  def full_name(%__MODULE__{first_name: first_name, last_name: last_name}) do
    "#{first_name} #{last_name}"
  end
end
