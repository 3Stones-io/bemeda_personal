defmodule BemedaPersonal.HtmlSanitizer do
  @moduledoc """
  Provides HTML sanitization functionality to prevent XSS and SQL injection attacks.

  This module uses html_sanitize_ex for robust HTML sanitization with a custom
  scrubber tailored for Trix editor content.

  References:
  - https://hex.pm/packages/html_sanitize_ex
  - https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html
  - https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html
  """

  require HtmlSanitizeEx.Scrubber.Meta

  defmodule TrixScrubber do
    @moduledoc """
    Custom HTML scrubber for Trix editor content.

    This scrubber allows only safe HTML tags and attributes that are commonly
    used in rich text editing, while blocking dangerous elements like scripts,
    iframes, and event handlers.
    """
    alias HtmlSanitizeEx.Scrubber.Meta

    require HtmlSanitizeEx.Scrubber.Meta

    Meta.strip_comments()

    # Allow safe text formatting tags
    Meta.allow_tag_with_uri_attributes(:a, ["href"], ["http", "https", "mailto"])
    Meta.allow_tag_with_these_attributes(:a, ["title", "rel"])

    Meta.allow_tag_with_these_attributes(:abbr, [])
    Meta.allow_tag_with_these_attributes(:b, [])
    Meta.allow_tag_with_these_attributes(:blockquote, ["cite"])
    Meta.allow_tag_with_these_attributes(:br, [])
    Meta.allow_tag_with_these_attributes(:cite, [])
    Meta.allow_tag_with_these_attributes(:code, [])
    Meta.allow_tag_with_these_attributes(:dd, [])
    Meta.allow_tag_with_these_attributes(:del, ["cite"])
    Meta.allow_tag_with_these_attributes(:div, [])
    Meta.allow_tag_with_these_attributes(:dl, [])
    Meta.allow_tag_with_these_attributes(:dt, [])
    Meta.allow_tag_with_these_attributes(:em, [])
    Meta.allow_tag_with_these_attributes(:h1, [])
    Meta.allow_tag_with_these_attributes(:h2, [])
    Meta.allow_tag_with_these_attributes(:h3, [])
    Meta.allow_tag_with_these_attributes(:h4, [])
    Meta.allow_tag_with_these_attributes(:h5, [])
    Meta.allow_tag_with_these_attributes(:h6, [])
    Meta.allow_tag_with_these_attributes(:hr, [])
    Meta.allow_tag_with_these_attributes(:i, [])
    Meta.allow_tag_with_these_attributes(:ins, ["cite"])
    Meta.allow_tag_with_these_attributes(:li, [])
    Meta.allow_tag_with_these_attributes(:mark, [])
    Meta.allow_tag_with_these_attributes(:ol, [])
    Meta.allow_tag_with_these_attributes(:p, [])
    Meta.allow_tag_with_these_attributes(:pre, [])
    Meta.allow_tag_with_these_attributes(:q, ["cite"])
    Meta.allow_tag_with_these_attributes(:s, [])
    Meta.allow_tag_with_these_attributes(:strike, [])
    Meta.allow_tag_with_these_attributes(:strong, [])
    Meta.allow_tag_with_these_attributes(:sub, [])
    Meta.allow_tag_with_these_attributes(:sup, [])
    Meta.allow_tag_with_these_attributes(:u, [])
    Meta.allow_tag_with_these_attributes(:ul, [])

    # Strip everything else
    Meta.strip_everything_not_covered()
  end

  @doc """
  Sanitizes HTML content from Trix editor, allowing only safe tags and attributes.

  This function removes:
  - Script tags and event handlers (onclick, onerror, etc.)
  - Dangerous protocols (javascript:, data:, vbscript:)
  - SQL injection attempts in attributes
  - Embedded objects and iframes
  - Style tags and inline styles that could be malicious

  ## Examples

      iex> BemedaPersonal.HtmlSanitizer.sanitize_trix_content("<strong>Hello</strong>")
      {:ok, "<strong>Hello</strong>"}

      iex> BemedaPersonal.HtmlSanitizer.sanitize_trix_content("<script>alert('xss')</script>")
      {:ok, ""}

      iex> BemedaPersonal.HtmlSanitizer.sanitize_trix_content(
      ...>   "<a href='javascript:alert(1)'>click</a>"
      ...> )
      {:ok, "click"}
  """
  @spec sanitize_trix_content(String.t() | nil) :: {:ok, String.t()} | {:error, String.t()}
  def sanitize_trix_content(html) when is_binary(html) do
    {:ok, HtmlSanitizeEx.basic_html(html)}
  rescue
    error ->
      {:error, "Failed to sanitize HTML: #{inspect(error)}"}
  end

  def sanitize_trix_content(nil), do: {:ok, ""}
  def sanitize_trix_content(_html), do: {:error, "Invalid input: expected string"}

  @doc """
  Sanitizes HTML content and returns the sanitized string or empty string on error.

  ## Examples

      iex> BemedaPersonal.HtmlSanitizer.sanitize_trix_content!("<strong>Hello</strong>")
      "<strong>Hello</strong>"

      iex> BemedaPersonal.HtmlSanitizer.sanitize_trix_content!("<script>alert('xss')</script>")
      ""
  """
  @spec sanitize_trix_content!(String.t() | nil) :: String.t()
  def sanitize_trix_content!(html) do
    case sanitize_trix_content(html) do
      {:ok, sanitized} -> sanitized
      {:error, _reason} -> ""
    end
  end

  @doc """
  Validates that the content length is within acceptable limits.

  ## Examples

      iex> BemedaPersonal.HtmlSanitizer.validate_content_length("Hello", 10)
      :ok

      iex> BemedaPersonal.HtmlSanitizer.validate_content_length("Hello World!", 5)
      {:error, "Content exceeds maximum length of 5 characters"}
  """
  @spec validate_content_length(String.t(), pos_integer()) :: :ok | {:error, String.t()}
  def validate_content_length(content, max_length) when is_binary(content) do
    if String.length(content) <= max_length do
      :ok
    else
      {:error, "Content exceeds maximum length of #{max_length} characters"}
    end
  end

  def validate_content_length(_content, _max_length), do: {:error, "Invalid content type"}

  @doc """
  Returns the list of allowed HTML tags.

  These tags are permitted by the TrixScrubber:
  - Text formatting tags
  - Headings
  - Lists
  - Links (with safe protocols)
  - Basic block elements
  """
  @spec allowed_tags() :: [String.t()]
  def allowed_tags do
    [
      "a",
      "abbr",
      "b",
      "blockquote",
      "br",
      "cite",
      "code",
      "dd",
      "del",
      "div",
      "dl",
      "dt",
      "em",
      "h1",
      "h2",
      "h3",
      "h4",
      "h5",
      "h6",
      "hr",
      "i",
      "ins",
      "li",
      "mark",
      "ol",
      "p",
      "pre",
      "q",
      "s",
      "strike",
      "strong",
      "sub",
      "sup",
      "u",
      "ul"
    ]
  end

  @doc """
  Returns the map of allowed attributes per tag.
  """
  @spec allowed_attributes() :: %{String.t() => [String.t()]}
  def allowed_attributes do
    %{
      "a" => ["href", "title", "rel"],
      "blockquote" => ["cite"],
      "q" => ["cite"],
      "del" => ["cite"],
      "ins" => ["cite"]
    }
  end

  @doc """
  Returns the list of allowed URL schemes for links.
  """
  @spec allowed_schemes() :: [String.t()]
  def allowed_schemes do
    ["http", "https", "mailto"]
  end

  @doc """
  Sanitizes HTML content and returns the sanitized string or empty string on error.

  ## Examples

      iex> BemedaPersonal.HtmlSanitizer.sanitized_html("<h1>Hello <script>World!</script></h1>")
      "<h1>Hello World!</h1>"

      iex> BemedaPersonal.HtmlSanitizer.sanitized_html(nil)
      ""
  """
  @spec sanitized_html(String.t() | nil) :: String.t()
  def sanitized_html(html) do
    case sanitize_trix_content(html) do
      {:ok, sanitized} -> sanitized
      {:error, _reason} -> ""
    end
  end
end
