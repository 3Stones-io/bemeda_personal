defmodule BemedaPersonalWeb.Components.Core.Typography do
  @moduledoc """
  Typography components using design tokens for consistent text styling.

  Provides standardized headings and text components that follow the
  design system's typography scale defined in Tailwind configuration.
  """

  use Phoenix.Component

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type rendered :: Phoenix.LiveView.Rendered.t()

  @doc """
  Renders a heading with consistent styling.

  ## Examples

      <.heading>Page Title</.heading>
      <.heading level="h2">Section Title</.heading>
      <.heading class="mb-4">Dashboard</.heading>
  """
  attr :level, :string, default: "h1", values: ["h1", "h2", "h3", "h4", "h5", "h6"]
  attr :class, :any, default: ""
  attr :rest, :global

  slot :inner_block, required: true

  @spec heading(assigns()) :: rendered()
  def heading(assigns) do
    ~H"""
    <h1 :if={@level == "h1"} class={["text-h1 text-gray-900", @class]} {@rest}>
      {render_slot(@inner_block)}
    </h1>
    <h2 :if={@level == "h2"} class={["text-h2 text-gray-900", @class]} {@rest}>
      {render_slot(@inner_block)}
    </h2>
    <h3 :if={@level == "h3"} class={["text-h3 text-gray-900", @class]} {@rest}>
      {render_slot(@inner_block)}
    </h3>
    <h4 :if={@level == "h4"} class={["text-h4 text-gray-900", @class]} {@rest}>
      {render_slot(@inner_block)}
    </h4>
    <h5 :if={@level == "h5"} class={["text-h5 text-gray-900", @class]} {@rest}>
      {render_slot(@inner_block)}
    </h5>
    <h6 :if={@level == "h6"} class={["text-h6 text-gray-900", @class]} {@rest}>
      {render_slot(@inner_block)}
    </h6>
    """
  end

  @doc """
  Renders a section heading (h2) with consistent styling.

  ## Examples

      <.section_heading>Section Title</.section_heading>
      <.section_heading class="mb-6">Recent Jobs</.section_heading>
  """
  attr :class, :any, default: ""
  attr :rest, :global

  slot :inner_block, required: true

  @spec section_heading(assigns()) :: rendered()
  def section_heading(assigns) do
    ~H"""
    <h2 class={["text-h2 text-gray-900", @class]} {@rest}>
      {render_slot(@inner_block)}
    </h2>
    """
  end

  @doc """
  Renders a subsection heading (h3) with consistent styling.

  ## Examples

      <.subsection_heading>Subsection Title</.subsection_heading>
      <.subsection_heading class="mb-4">About Company</.subsection_heading>
  """
  attr :class, :any, default: ""
  attr :rest, :global

  slot :inner_block, required: true

  @spec subsection_heading(assigns()) :: rendered()
  def subsection_heading(assigns) do
    ~H"""
    <h3 class={["text-h3 text-gray-900", @class]} {@rest}>
      {render_slot(@inner_block)}
    </h3>
    """
  end

  @doc """
  Renders a subtitle with consistent styling.

  ## Examples

      <.subtitle>Manage your job postings</.subtitle>
      <.subtitle class="text-gray-500">Page description</.subtitle>
  """
  attr :class, :any, default: ""
  attr :rest, :global

  slot :inner_block, required: true

  @spec subtitle(assigns()) :: rendered()
  def subtitle(assigns) do
    ~H"""
    <p class={["text-body text-gray-600", @class]} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders body text with consistent styling.

  ## Examples

      <.text>Regular body text</.text>
      <.text variant="body-sm">Small text</.text>
      <.text variant="caption">Caption text</.text>
      <.text class="text-gray-500">Muted text</.text>
  """
  attr :variant, :string, default: "body", values: ["body-lg", "body", "body-sm", "caption"]
  attr :class, :any, default: ""
  attr :rest, :global

  slot :inner_block, required: true

  @spec text(assigns()) :: rendered()
  def text(assigns) do
    ~H"""
    <p class={[text_variant_classes(@variant), @class]} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders small text with consistent styling.

  ## Examples

      <.small_text>Small supporting text</.small_text>
      <.small_text class="text-gray-500">Caption or helper text</.small_text>
  """
  attr :class, :any, default: ""
  attr :rest, :global

  slot :inner_block, required: true

  @spec small_text(assigns()) :: rendered()
  def small_text(assigns) do
    ~H"""
    <p class={["text-body-sm text-gray-600", @class]} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders caption text with consistent styling.

  ## Examples

      <.caption>Caption text</.caption>
      <.caption class="text-gray-500">Very small helper text</.caption>
  """
  attr :class, :any, default: ""
  attr :rest, :global

  slot :inner_block, required: true

  @spec caption(assigns()) :: rendered()
  def caption(assigns) do
    ~H"""
    <p class={["text-caption text-gray-500", @class]} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a link with consistent styling.

  ## Examples

      <.text_link href="/external-page">External link</.text_link>
      <.text_link navigate="/other-page">Internal navigation</.text_link>
      <.text_link patch="/same-page">Same LiveView navigation</.text_link>
  """
  attr :href, :string, default: nil
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :class, :any, default: ""
  attr :rest, :global

  slot :inner_block, required: true

  @spec text_link(assigns()) :: rendered()
  def text_link(assigns) do
    validate_link_attributes!(assigns)

    ~H"""
    <a
      :if={@href}
      href={@href}
      class={["text-primary-600 hover:text-primary-700 underline hover:no-underline", @class]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </a>
    <.link
      :if={@navigate}
      navigate={@navigate}
      class={["text-primary-600 hover:text-primary-700 underline hover:no-underline", @class]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    <.link
      :if={@patch}
      patch={@patch}
      class={["text-primary-600 hover:text-primary-700 underline hover:no-underline", @class]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  defp validate_link_attributes!(assigns) do
    link_attrs = [assigns[:href], assigns[:navigate], assigns[:patch]]
    defined_attrs = Enum.reject(link_attrs, &is_nil/1)

    case length(defined_attrs) do
      0 -> raise ArgumentError, "text_link requires exactly one of: href, navigate, or patch"
      1 -> :ok
      _count -> raise ArgumentError, "text_link accepts only one of: href, navigate, or patch"
    end
  end

  defp text_variant_classes("body-lg"), do: "text-body-lg text-gray-700"
  defp text_variant_classes("body"), do: "text-body text-gray-700"
  defp text_variant_classes("body-sm"), do: "text-body-sm text-gray-600"
  defp text_variant_classes("caption"), do: "text-caption text-gray-500"
end
