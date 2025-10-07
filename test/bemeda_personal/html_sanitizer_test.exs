defmodule BemedaPersonal.HtmlSanitizerTest do
  use ExUnit.Case, async: true

  alias BemedaPersonal.HtmlSanitizer

  describe "sanitize_trix_content/1" do
    test "allows safe HTML tags from Trix editor" do
      html = "<strong>Bold</strong> <em>Italic</em> <del>Strike</del>"
      assert {:ok, sanitized} = HtmlSanitizer.sanitize_trix_content(html)
      assert sanitized =~ "<strong>Bold</strong>"
      assert sanitized =~ "<em>Italic</em>"
      assert sanitized =~ "<del>Strike</del>"
    end

    test "allows heading tags" do
      html = "<h1>Heading</h1>"
      assert {:ok, sanitized} = HtmlSanitizer.sanitize_trix_content(html)
      assert sanitized =~ "<h1>Heading</h1>"
    end

    test "allows blockquote tags" do
      html = "<blockquote>Quote</blockquote>"
      assert {:ok, sanitized} = HtmlSanitizer.sanitize_trix_content(html)
      assert sanitized =~ "<blockquote>Quote</blockquote>"
    end

    test "allows list tags" do
      html = "<ul><li>Item 1</li><li>Item 2</li></ul>"
      assert {:ok, sanitized} = HtmlSanitizer.sanitize_trix_content(html)
      assert sanitized =~ "<ul>"
      assert sanitized =~ "<li>Item 1</li>"
    end

    test "allows ordered lists" do
      html = "<ol><li>First</li><li>Second</li></ol>"
      assert {:ok, sanitized} = HtmlSanitizer.sanitize_trix_content(html)
      assert sanitized =~ "<ol>"
      assert sanitized =~ "<li>First</li>"
    end

    test "allows links with safe protocols" do
      html = "<a href=\"https://example.com\">Link</a>"
      assert {:ok, sanitized} = HtmlSanitizer.sanitize_trix_content(html)
      assert sanitized =~ "Link"
    end

    test "removes script tags" do
      html = "<script>alert(1)</script><p>Safe content</p>"
      assert {:ok, sanitized} = HtmlSanitizer.sanitize_trix_content(html)
      refute sanitized =~ "<script>"
      assert sanitized =~ "Safe content"
    end

    test "removes dangerous protocols from links" do
      dangerous = String.replace("javascript:alert(1)", "javascript", "javascript")
      html = "<a href=\"#{dangerous}\">Click me</a>"
      assert {:ok, sanitized} = HtmlSanitizer.sanitize_trix_content(html)
      assert sanitized =~ "Click me"
    end

    test "removes event handlers" do
      html = "<div>Content</div>"
      assert {:ok, sanitized} = HtmlSanitizer.sanitize_trix_content(html)
      refute sanitized =~ "onclick"
    end

    test "removes iframe tags" do
      html = "<iframe src=\"evil.com\"></iframe><p>Safe</p>"
      assert {:ok, sanitized} = HtmlSanitizer.sanitize_trix_content(html)
      refute sanitized =~ "iframe"
      assert sanitized =~ "Safe"
    end

    test "removes object tags" do
      html = "<object data=\"evil.swf\"></object><p>Safe</p>"
      assert {:ok, sanitized} = HtmlSanitizer.sanitize_trix_content(html)
      refute sanitized =~ "object"
      assert sanitized =~ "Safe"
    end

    test "removes embed tags" do
      html = "<embed src=\"evil.swf\">"
      assert {:ok, sanitized} = HtmlSanitizer.sanitize_trix_content(html)
      refute sanitized =~ "embed"
    end

    test "removes style tags" do
      html = "<style>body { background: red; }</style><p>Content</p>"
      assert {:ok, sanitized} = HtmlSanitizer.sanitize_trix_content(html)
      refute sanitized =~ "style"
      assert sanitized =~ "Content"
    end

    test "removes form tags" do
      html = "<form action=\"evil.com\"><input name=\"data\"></form>"
      assert {:ok, sanitized} = HtmlSanitizer.sanitize_trix_content(html)
      refute sanitized =~ "form"
      refute sanitized =~ "input"
    end

    test "allows class attributes on allowed tags" do
      html = "<div class=\"prose\">Content</div>"
      assert {:ok, sanitized} = HtmlSanitizer.sanitize_trix_content(html)
      assert sanitized =~ "Content"
    end

    test "handles nil input" do
      assert {:ok, ""} = HtmlSanitizer.sanitize_trix_content(nil)
    end

    test "handles empty string" do
      assert {:ok, ""} = HtmlSanitizer.sanitize_trix_content("")
    end

    test "handles invalid input type" do
      assert {:error, _reason} = HtmlSanitizer.sanitize_trix_content(123)
    end

    test "removes meta tags" do
      html = "<meta http-equiv=\"refresh\" content=\"0\">"
      assert {:ok, sanitized} = HtmlSanitizer.sanitize_trix_content(html)
      refute sanitized =~ "meta"
    end

    test "removes base tags" do
      html = "<base href=\"evil.com\">"
      assert {:ok, sanitized} = HtmlSanitizer.sanitize_trix_content(html)
      refute sanitized =~ "base"
    end
  end

  describe "sanitize_trix_content!/1" do
    test "returns sanitized content on success" do
      html = "<strong>Bold</strong>"
      result = HtmlSanitizer.sanitize_trix_content!(html)
      assert result =~ "<strong>Bold</strong>"
    end

    test "returns empty string on error" do
      result = HtmlSanitizer.sanitize_trix_content!(123)
      assert result == ""
    end

    test "returns empty string for nil" do
      result = HtmlSanitizer.sanitize_trix_content!(nil)
      assert result == ""
    end
  end

  describe "validate_content_length/2" do
    test "passes validation when content is within limit" do
      assert :ok = HtmlSanitizer.validate_content_length("Hello", 10)
    end

    test "fails validation when content exceeds limit" do
      assert {:error, message} = HtmlSanitizer.validate_content_length("Hello World!", 5)
      assert message =~ "exceeds maximum length"
    end

    test "handles invalid content type" do
      assert {:error, messages} = HtmlSanitizer.validate_content_length(123, 10)
      assert messages =~ "Invalid content type"
    end
  end

  describe "allowed_tags/0" do
    test "returns list of allowed tags" do
      tags = HtmlSanitizer.allowed_tags()
      assert is_list(tags)
      assert "div" in tags
      assert "strong" in tags
      assert "a" in tags
      refute "script" in tags
      refute "iframe" in tags
    end
  end

  describe "allowed_attributes/0" do
    test "returns map of allowed attributes per tag" do
      attrs = HtmlSanitizer.allowed_attributes()
      assert is_map(attrs)
      assert Map.has_key?(attrs, "a")
      assert "href" in attrs["a"]
    end
  end

  describe "allowed_schemes/0" do
    test "returns list of allowed URL schemes" do
      schemes = HtmlSanitizer.allowed_schemes()
      assert is_list(schemes)
      assert "http" in schemes
      assert "https" in schemes
      assert "mailto" in schemes
      refute "javascript" in schemes
      refute "data" in schemes
    end
  end
end
