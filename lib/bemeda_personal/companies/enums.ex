defmodule BemedaPersonal.Companies.Enums do
  @moduledoc false

  alias BemedaPersonal.JobPostings

  @type enum_value() :: atom()
  @type enum_values() :: [enum_value()]

  @organization_types [
    :"Care Home",
    :Clinic,
    :"Home Care Service",
    :Hospital,
    :"Medical Center",
    :"Private Practice",
    :Other
  ]

  @spec organization_types() :: enum_values()
  def organization_types, do: @organization_types

  @spec locations() :: enum_values()
  def locations, do: JobPostings.Enums.regions()
end
