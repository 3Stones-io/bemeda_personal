defmodule BemedaPersonal.EctoEnumHelper do
  @moduledoc """
  Conveniences for translations.
  """

  @doc """
  Returns all translated enum values for the select options.
  """
  @spec translated_enum_options(module, String.t(), atom) :: [{String.t(), atom}]
  def translated_enum_options(module, domain, field) do
    module
    |> Ecto.Enum.values(field)
    |> Enum.map(fn value ->
      {translate_enum(domain, value), value}
    end)
  end

  defp translate_enum(domain, value) when is_atom(value) do
    value_string = Atom.to_string(value)
    Gettext.dgettext(BemedaPersonalWeb.Gettext, domain, value_string)
  end
end
