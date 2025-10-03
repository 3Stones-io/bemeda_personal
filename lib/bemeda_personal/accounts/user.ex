defmodule BemedaPersonal.Accounts.User do
  @moduledoc false

  use Ecto.Schema
  use Gettext, backend: BemedaPersonalWeb.Gettext

  import Ecto.Changeset

  alias BemedaPersonal.JobPostings.Enums

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
    field :date_of_birth, :date
    field :department, Ecto.Enum, values: Enums.departments()
    field :email, :string
    field :first_name, :string
    field :gender, Ecto.Enum, values: [:male, :female]
    field :hashed_password, :string, redact: true
    field :last_name, :string
    field :locale, Ecto.Enum, values: [:de, :en, :fr, :it], default: :de
    field :medical_role, Ecto.Enum, values: Enums.professions()
    field :password, :string, virtual: true, redact: true
    field :phone, :string
    field :street, :string
    field :user_type, Ecto.Enum, values: [:job_seeker, :employer], default: :job_seeker
    field :zip_code, :string

    # Magic link fields
    field :magic_link_enabled, :boolean, default: false
    field :last_magic_link_sent_at, :utc_datetime
    field :magic_link_send_count, :integer, default: 0
    field :passwordless_only, :boolean, default: false
    field :last_sudo_at, :utc_datetime
    field :magic_link_reset_at, :utc_datetime

    has_one :resume, BemedaPersonal.Resumes.Resume
    has_many :magic_tokens, BemedaPersonal.Accounts.MagicLinkToken
    has_one :media_asset, BemedaPersonal.Media.MediaAsset

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
      :department,
      :email,
      :first_name,
      :gender,
      :last_name,
      :locale,
      :medical_role,
      :password,
      :street,
      :user_type,
      :zip_code
    ])
    |> validate_email(opts)
    |> validate_password(opts)
    |> validate_name()
    |> validate_personal_info()
    |> validate_job_seeker_fields()
  end

  @doc """
  A user changeset for Step 1 of registration (basic information).

  This changeset validates only the fields relevant to Step 1:
  - email, first_name, last_name, password

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
  @spec registration_step1_changeset(t() | changeset(), attrs(), opts()) :: changeset()
  def registration_step1_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :first_name, :last_name, :password, :date_of_birth, :phone])
    |> validate_email(opts)
    |> validate_password(opts)
    |> validate_name()
  end

  @doc """
  A user changeset for Step 2 of registration (personal information).

  This changeset validates only the fields relevant to Step 2:
  - gender, street, zip_code, city, country
  - For job seekers: medical_role, department

  For final form submission validation, it also casts Step 1 fields
  to ensure complete validation when displaying errors.
  """
  @spec registration_step2_changeset(t() | changeset(), attrs(), opts()) :: changeset()
  def registration_step2_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [
      :city,
      :country,
      :department,
      :email,
      :first_name,
      :gender,
      :last_name,
      :medical_role,
      :password,
      :street,
      :user_type,
      :zip_code
    ])
    |> validate_email(opts)
    |> validate_name()
    |> validate_password(opts)
    |> validate_personal_info()
    |> validate_job_seeker_fields()
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

  defp validate_personal_info(changeset) do
    changeset
    |> validate_required([:city, :country, :street, :zip_code])
    |> validate_length(:city, min: 1, max: 100)
    |> validate_length(:country, min: 1, max: 100)
    |> validate_length(:street, min: 1, max: 255)
    |> validate_length(:zip_code, min: 1, max: 20)
  end

  defp validate_job_seeker_fields(changeset) do
    user_type = get_field(changeset, :user_type)

    if user_type == :job_seeker do
      validate_required(changeset, [:medical_role, :department])
    else
      changeset
    end
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
      :street,
      :locale,
      :zip_code
    ])
    |> validate_required([:first_name, :last_name])
    |> validate_length(:first_name, min: 1, max: 160)
    |> validate_length(:last_name, min: 1, max: 160)
    |> validate_personal_info()
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

  @doc """
  Changeset for enabling/disabling magic link authentication
  """
  @spec magic_link_preferences_changeset(t() | changeset(), attrs(), keyword()) :: changeset()
  def magic_link_preferences_changeset(user, attrs, opts \\ []) do
    # Handle checkbox fields carefully:
    # - For form submissions (string keys), missing checkboxes should default to false
    # - For programmatic updates (atom keys), only update the fields that are explicitly provided
    # - For display (empty map with for_display: true), show current values without defaults
    for_display = Keyword.get(opts, :for_display, false)

    attrs_with_defaults =
      cond do
        Map.has_key?(attrs, "magic_link_enabled") or Map.has_key?(attrs, "passwordless_only") ->
          # String keys (form submission) - add string defaults for missing checkboxes
          attrs
          |> Map.put_new("magic_link_enabled", false)
          |> Map.put_new("passwordless_only", false)

        Map.has_key?(attrs, :magic_link_enabled) and Map.has_key?(attrs, :passwordless_only) ->
          # Atom keys with both fields - this is an explicit update of both
          attrs

        Map.has_key?(attrs, :magic_link_enabled) or Map.has_key?(attrs, :passwordless_only) ->
          # Atom keys with only one field - partial update, don't add defaults
          attrs

        for_display ->
          # Empty map for display - show current values, don't add defaults
          attrs

        true ->
          # Empty map for form submission - add string defaults (unchecked checkboxes)
          attrs
          |> Map.put_new("magic_link_enabled", false)
          |> Map.put_new("passwordless_only", false)
      end

    user
    |> cast(attrs_with_defaults, [:magic_link_enabled, :passwordless_only])
    |> validate_magic_link_preferences()
  end

  defp validate_magic_link_preferences(changeset) do
    changeset
    |> maybe_disable_passwordless_only()
    |> validate_change(:passwordless_only, fn
      :passwordless_only, true ->
        magic_link_enabled = get_field(changeset, :magic_link_enabled)

        if magic_link_enabled != true do
          [{:passwordless_only, "can only be enabled when magic links are enabled"}]
        else
          []
        end

      :passwordless_only, _value ->
        []
    end)
  end

  defp maybe_disable_passwordless_only(changeset) do
    case get_change(changeset, :magic_link_enabled) do
      false -> put_change(changeset, :passwordless_only, false)
      _other_value -> changeset
    end
  end

  @doc """
  Updates tracking fields when magic link is sent
  """
  @spec track_magic_link_sent(t()) :: {:ok, t()} | {:error, changeset()}
  def track_magic_link_sent(user) do
    user
    |> change()
    |> put_change(:last_magic_link_sent_at, DateTime.utc_now(:second))
    |> put_change(:magic_link_send_count, (user.magic_link_send_count || 0) + 1)
    |> BemedaPersonal.Repo.update()
  end

  @doc """
  Records sudo mode authentication
  """
  @spec record_sudo_authentication(t()) :: {:ok, t()} | {:error, changeset()}
  def record_sudo_authentication(user) do
    user
    |> change(last_sudo_at: DateTime.utc_now(:second))
    |> BemedaPersonal.Repo.update()
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
  Returns the full name of the user.
  """
  @spec full_name(t()) :: String.t()
  def full_name(%__MODULE__{first_name: first_name, last_name: last_name}) do
    "#{first_name} #{last_name}"
  end
end
