require 'test_helper'

class TestIroRubyParser < Minitest::Test
  def parse(source)
    Iro::Ruby::Parser.tokens(source)
  end

  def test_tokens_string
    tokens = parse(<<~RUBY)
      "foo"
    RUBY

    assert_equal(
      {
        'Delimiter' => [[1,1,1], [1,5,1]],
        'String' => [[1,2,3]]
      },
      tokens
    )
  end

  def test_tokens_lvar
    tokens = parse(<<~RUBY)
      p x
      x = 1
      p x
    RUBY

    assert_equal(
      {
        'Number' => [[2,5,1]],
        'rubyLocalVariable' => [[3, 3, 1]],
      },
      tokens
    )
  end
end
