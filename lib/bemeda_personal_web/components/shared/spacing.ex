defmodule BemedaPersonalWeb.Components.Shared.Spacing do
  @moduledoc """
  Consistent spacing utilities using design tokens.

  Provides standardized spacing classes for common layout patterns
  to ensure visual consistency across the application.
  """

  @doc """
  Container padding for responsive layouts.
  Uses consistent horizontal padding that scales with screen size.
  """
  @spec container_padding() :: String.t()
  def container_padding, do: "px-sm sm:px-md lg:px-lg"

  @doc """
  Section spacing for vertical separation between major page sections.
  """
  @spec section_spacing() :: String.t()
  def section_spacing, do: "py-lg"

  @doc """
  Large section spacing for greater visual separation.
  """
  @spec section_spacing_large() :: String.t()
  def section_spacing_large, do: "py-xl"

  @doc """
  Card padding for content inside cards and panels.
  """
  @spec card_padding() :: String.t()
  def card_padding, do: "p-md"

  @doc """
  Small card padding for compact cards.
  """
  @spec card_padding_small() :: String.t()
  def card_padding_small, do: "p-sm"

  @doc """
  Large card padding for spacious cards.
  """
  @spec card_padding_large() :: String.t()
  def card_padding_large, do: "p-lg"

  @doc """
  Form spacing for consistent vertical rhythm in forms.
  """
  @spec form_spacing() :: String.t()
  def form_spacing, do: "space-y-md"

  @doc """
  Compact form spacing for tighter layouts.
  """
  @spec form_spacing_compact() :: String.t()
  def form_spacing_compact, do: "space-y-sm"

  @doc """
  Button group spacing for horizontal button layouts.
  """
  @spec button_group_spacing() :: String.t()
  def button_group_spacing, do: "space-x-sm"

  @doc """
  Stack spacing for vertical element stacking.
  """
  @spec stack_spacing() :: String.t()
  def stack_spacing, do: "space-y-sm"

  @doc """
  Large stack spacing for more visual separation.
  """
  @spec stack_spacing_large() :: String.t()
  def stack_spacing_large, do: "space-y-md"

  @doc """
  Grid gap for consistent spacing in grid layouts.
  """
  @spec grid_gap() :: String.t()
  def grid_gap, do: "gap-md"

  @doc """
  Small grid gap for compact grids.
  """
  @spec grid_gap_small() :: String.t()
  def grid_gap_small, do: "gap-sm"

  @doc """
  Large grid gap for spacious grids.
  """
  @spec grid_gap_large() :: String.t()
  def grid_gap_large, do: "gap-lg"

  @doc """
  List spacing for items in lists.
  """
  @spec list_spacing() :: String.t()
  def list_spacing, do: "space-y-xs"

  @doc """
  Page header spacing for consistent page headers.
  """
  @spec page_header_spacing() :: String.t()
  def page_header_spacing, do: "mb-lg"

  @doc """
  Content spacing for main content areas.
  """
  @spec content_spacing() :: String.t()
  def content_spacing, do: "space-y-lg"
end
