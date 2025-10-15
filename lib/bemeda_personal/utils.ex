defmodule BemedaPersonal.Utils do
  @moduledoc false

  import Ecto.Changeset

  @spec validate_e164_phone_number(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def validate_e164_phone_number(changeset, field) do
    validate_format(changeset, field, ~r/^\+[1-9]\d{1,14}$/,
      message: "must be in E.164 format (e.g., +41791234567)"
    )
  end
end
