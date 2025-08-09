defmodule BemedaPersonalWeb.Components.Shared.Spacing do
  @moduledoc """
  Consistent spacing utilities using design tokens.

  Provides standardized spacing classes for common layout patterns
  to ensure visual consistency across the application.
  """

  @type spacing_class :: String.t()

  @doc """
  Container padding for responsive layouts.
  Uses consistent horizontal padding that scales with screen size.
  """
  @spec container_padding() :: spacing_class()
  def container_padding, do: "px-sm sm:px-md lg:px-lg"

  @doc """
  Section spacing for vertical separation between major page sections.
  """
  @spec section_spacing() :: spacing_class()
  def section_spacing, do: "py-lg"

  @doc """
  Large section spacing for greater visual separation.
  """
  @spec section_spacing_large() :: spacing_class()
  def section_spacing_large, do: "py-xl"

  @doc """
  Card padding for content inside cards and panels.
  """
  @spec card_padding() :: spacing_class()
  def card_padding, do: "p-md"

  @doc """
  Small card padding for compact cards.
  """
  @spec card_padding_small() :: spacing_class()
  def card_padding_small, do: "p-sm"

  @doc """
  Large card padding for spacious cards.
  """
  @spec card_padding_large() :: spacing_class()
  def card_padding_large, do: "p-lg"

  @doc """
  Form spacing for consistent vertical rhythm in forms.
  """
  @spec form_spacing() :: spacing_class()
  def form_spacing, do: "space-y-md"

  @doc """
  Compact form spacing for tighter layouts.
  """
  @spec form_spacing_compact() :: spacing_class()
  def form_spacing_compact, do: "space-y-sm"

  @doc """
  Button group spacing for horizontal button layouts.
  """
  @spec button_group_spacing() :: spacing_class()
  def button_group_spacing, do: "space-x-sm"

  @doc """
  Stack spacing for vertical element stacking.
  """
  @spec stack_spacing() :: spacing_class()
  def stack_spacing, do: "space-y-sm"

  @doc """
  Large stack spacing for more visual separation.
  """
  @spec stack_spacing_large() :: spacing_class()
  def stack_spacing_large, do: "space-y-md"

  @doc """
  Grid gap for consistent spacing in grid layouts.
  """
  @spec grid_gap() :: spacing_class()
  def grid_gap, do: "gap-md"

  @doc """
  Small grid gap for compact grids.
  """
  @spec grid_gap_small() :: spacing_class()
  def grid_gap_small, do: "gap-sm"

  @doc """
  Large grid gap for spacious grids.
  """
  @spec grid_gap_large() :: spacing_class()
  def grid_gap_large, do: "gap-lg"

  @doc """
  List spacing for items in lists.
  """
  @spec list_spacing() :: spacing_class()
  def list_spacing, do: "space-y-xs"

  @doc """
  Page header spacing for consistent page headers.
  """
  @spec page_header_spacing() :: spacing_class()
  def page_header_spacing, do: "mb-lg"

  @doc """
  Content spacing for main content areas.
  """
  @spec content_spacing() :: spacing_class()
  def content_spacing, do: "space-y-lg"
end
