defmodule BemedaPersonalWeb.Storybook.Core do
  use PhoenixStorybook.Index

  @spec folder_icon() :: PhoenixStorybook.Components.Icon.t()
  def folder_icon, do: {:fa, "cube", :thin, "stroke-current"}

  @spec folder_name() :: String.t()
  def folder_name, do: "Core Components"

  @spec entry(String.t()) :: keyword(String.t() | PhoenixStorybook.Components.Icon.t())
  def entry("button"), do: [name: "Button"]
  def entry("input"), do: [name: "Input"]
  def entry("card"), do: [name: "Card"]
  def entry("typography"), do: [name: "Typography"]
  def entry("modal"), do: [name: "Modal"]
  def entry("icon"), do: [name: "Icon"]
end
