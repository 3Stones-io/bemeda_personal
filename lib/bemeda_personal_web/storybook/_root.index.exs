defmodule BemedaPersonalWeb.Storybook.Root do
  @moduledoc """
  Root index for Phoenix Storybook.

  This module organizes all stories and folders in the Storybook navigation.
  """

  use PhoenixStorybook.Index

  @spec folder_icon() :: PhoenixStorybook.Components.Icon.t()
  def folder_icon, do: {:fa, "book", :light, "fill-current"}

  @spec folder_name() :: String.t()
  def folder_name, do: "Bemeda Personal"

  @spec entry(String.t()) :: keyword(String.t() | PhoenixStorybook.Components.Icon.t())
  def entry("core"), do: [name: "Core Components", icon: {:fa, "cube", :thin, "stroke-current"}]

  def entry("figma"),
    do: [name: "Figma Design System", icon: {:fa, "palette", :thin, "stroke-current"}]
end
