defmodule BemedaPersonalWeb.HtmlHelper do
  @moduledoc """
  Helper functions for safely rendering HTML content.
  """

  import Phoenix.HTML

  alias BemedaPersonal.HtmlSanitizer

  @doc """
  Safely renders HTML content that has been sanitized.

  This function should be used instead of `raw/1` when displaying user-generated content.
  The content is assumed to have already been sanitized during input validation.

  ## Examples

      <%= safe_html(@job_posting.description) %>
  """
  @spec safe_html(String.t() | nil) :: Phoenix.HTML.safe()
  def safe_html(nil), do: raw("")
  def safe_html(""), do: raw("")

  def safe_html(content) when is_binary(content) do
    raw(content)
  end

  def safe_html(_content), do: raw("")

  @doc """
  Renders HTML content with runtime sanitization as an additional safety layer.

  Use this for legacy data or when you want extra protection.
  Note: This adds performance overhead, so prefer pre-sanitized content when possible.

  ## Examples

      <%= sanitized_html(@legacy_content) %>
  """
  @spec sanitized_html(String.t() | nil) :: Phoenix.HTML.safe()
  def sanitized_html(nil), do: raw("")
  def sanitized_html(""), do: raw("")

  def sanitized_html(content) when is_binary(content) do
    case HtmlSanitizer.sanitize_trix_content(content) do
      {:ok, sanitized} -> raw(sanitized)
      {:error, _reason} -> raw("")
    end
  end

  def sanitized_html(_content), do: raw("")
end
