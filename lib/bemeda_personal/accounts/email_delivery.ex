defmodule BemedaPersonal.Accounts.EmailDelivery do
  @moduledoc """
  Shared email delivery functionality for user and interview notifications.
  """

  use Gettext, backend: BemedaPersonalWeb.Gettext

  import Swoosh.Email

  @type email :: Swoosh.Email.t()
  @type user :: BemedaPersonal.Accounts.User.t()

  @from {"BemedaPersonal", "contact@mg.bemeda-personal.ch"}

  @doc """
  Delivers an email to a user with the given subject and body content.
  """
  @spec deliver(user(), String.t(), String.t(), String.t()) ::
          {:ok, email()} | {:error, any()}
  def deliver(%BemedaPersonal.Accounts.User{} = recipient, subject, html_body, text_body) do
    email =
      new()
      |> to({"#{recipient.first_name} #{recipient.last_name}", recipient.email})
      |> from(@from)
      |> subject(subject)
      |> text_body(text_body)
      |> html_body(html_body)

    case BemedaPersonal.Mailer.deliver(email) do
      {:ok, _metadata} ->
        {:ok, email}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Sets the locale based on user's preferences.
  """
  @spec put_locale(user()) :: nil | binary()
  def put_locale(user) do
    user.locale
    |> Atom.to_string()
    |> Gettext.put_locale()
  end
end
