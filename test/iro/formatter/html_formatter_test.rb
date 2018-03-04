require 'test_helper'

class TestHTMLFormatter < Minitest::Test
  def unescape(source)
    CGI.unescapeHTML(Sanitize.fragment(source))
  end

  def format(source)
    highlight = Iro::Ruby::Parser.tokens(source)
    Iro::Formatter::HTMLFormatter.format(source, highlight)
  end

  def test_equivalent
    source = File.read(__FILE__)
    html = format(source)
    assert html.include?('<span')
    assert_equal source, unescape(html + "\n")
  end

  def test_lt
    source = "<"
    assert_equal "&lt;", format(source)
  end

  def test_gt
    source = ">"
    assert_equal "&gt;", format(source)
  end

  def test_xss
    source = %q!'<script>alert("XSS")</script>'!
    assert_equal "<span class=\"Delimiter\">&#39;</span><span class=\"String\">&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;</span><span class=\"Delimiter\">&#39;</span>",
                 format(source)
  end
end
