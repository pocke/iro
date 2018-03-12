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

  def test_tokens_backtick
    tokens = parse(<<~RUBY)
      `ls -a`
    RUBY

    assert_equal(
      {
        'Delimiter' => [[1,1,1], [1,7,1]],
        'String' => [[1,2,5]]
      },
      tokens
    )
  end

  def test_tokens_ivar
    tokens = parse(<<~RUBY)
      @foo = a
      p @foo
    RUBY
    assert_equal(
      {
        'rubyInstanceVariable' => [[1, 1, 4], [2, 3, 4]],
      },
      tokens
    )
  end

  def test_tokens_cvar
    tokens = parse(<<~RUBY)
      @@foo = a
      p @@foo
    RUBY
    assert_equal(
      {
        'rubyClassVariable' => [[1, 1, 5], [2, 3, 5]],
      },
      tokens
    )
  end

  def test_tokens_gvar
    tokens = parse(<<~RUBY)
      $foo = a
      p $foo
    RUBY
    assert_equal(
      {
        'rubyGlobalVariable' => [[1, 1, 4], [2, 3, 4]],
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

  def test_tokens_kw
    tokens = parse(<<~RUBY)
      if foo
      end
    RUBY
    assert_equal(
      {
        "Keyword" => [[1, 1, 2], [2, 1, 3]]
      },
      tokens
    )

    tokens = parse(<<~RUBY)
      def foo
      end
    RUBY
    assert_equal(
      {
        "rubyDefine" => [[1, 1, 3]],
        "Keyword" => [[2, 1, 3]],
        "rubyFunction" => [[1, 5, 3]],
      },
      tokens
    )
  end

  def test_defs
    tokens = parse(<<~RUBY)
      def self.foo
      end
    RUBY
    assert_equal(
      {
        "rubyDefine" => [[1, 1, 3]],
        "Keyword" => [[2, 1, 3]],
        "rubyFunction" => [[1, 10, 3]],
      },
      tokens
    )
  end

  def test_def_def
    tokens = parse(<<~RUBY)
      def def
      end
    RUBY
    assert_equal(
      {
        "rubyDefine" => [[1, 1, 3]],
        "Keyword" => [[2, 1, 3]],
        "rubyFunction" => [[1, 5, 3]],
      },
      tokens
    )
  end

  def test_symbol_literal
    tokens = parse(<<~RUBY)
      :foo
    RUBY
    assert_equal(
      {
        "rubySymbol" => [[1, 2, 3]],
        "rubySymbolDelimiter" => [[1, 1, 1]]
      },
      tokens
    )
  end

  def test_symbol_with_Xvar
    tokens = parse(<<~RUBY)
      :$foo
      :@foo
      :@@foo
    RUBY
    assert_equal(
      {
        "rubySymbol" => [[1, 2, 4], [2, 2, 4], [3, 2, 5]],
        "rubySymbolDelimiter" => [[1, 1, 1], [2, 1, 1], [3, 1, 1]]
      },
      tokens.reject { |_, v| v.empty? }
    )
  end
end
