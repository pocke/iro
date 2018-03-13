require 'test_helper'

class TestIroRubyParser < Minitest::Test
  def assert_parse(expected, source)
    got = Iro::Ruby::Parser.tokens(source)
    assert_equal(expected, got)
  end

  def test_tokens_string
    assert_parse(
      {
        'Delimiter' => [[1,1,1], [1,5,1]],
        'String' => [[1,2,3]]
      }, <<~RUBY
        "foo"
      RUBY
    )
  end

  def test_tokens_backtick
    assert_parse(
      {
        'Delimiter' => [[1,1,1], [1,7,1]],
        'String' => [[1,2,5]]
      }, <<~RUBY
        `ls -a`
      RUBY
    )
  end

  def test_tokens_label
    assert_parse(
      {
        'rubySymbol' => [[1, 2, 4], [2, 7, 4]],
        'rubyDefine' => [[2, 1, 3]],
        'Keyword' => [[3, 1, 3]],
        'rubyFunction' => [[2, 5, 1]],
      }, <<~RUBY
        {foo: bar}
        def a foo: bar
        end
      RUBY
    )
  end

  def test_tokens_ivar
    assert_parse(
      {
        'rubyInstanceVariable' => [[1, 1, 4], [2, 3, 4]],
      }, <<~RUBY
        @foo = a
        p @foo
      RUBY
    )
  end

  def test_tokens_cvar
    assert_parse(
      {
        'rubyClassVariable' => [[1, 1, 5], [2, 3, 5]],
      }, <<~RUBY
        @@foo = a
        p @@foo
      RUBY
    )
  end

  def test_tokens_gvar
    assert_parse(
      {
        'rubyGlobalVariable' => [[1, 1, 4], [2, 3, 4]],
      }, <<~RUBY
        $foo = a
        p $foo
      RUBY
    )
  end

  def test_tokens_lvar
    assert_parse(
      {
        'Number' => [[2,5,1]],
        'rubyLocalVariable' => [[3, 3, 1]],
      }, <<~RUBY
        p x
        x = 1
        p x
      RUBY
    )
  end

  def test_tokens_kw
    assert_parse(
      {
        "Keyword" => [[1, 1, 2], [2, 1, 3]]
      }, <<~RUBY
        if foo
        end
      RUBY
    )

    assert_parse(
      {
        "rubyDefine" => [[1, 1, 3]],
        "Keyword" => [[2, 1, 3]],
        "rubyFunction" => [[1, 5, 3]],
      }, <<~RUBY
        def foo
        end
      RUBY
    )
  end

  def test_defs
    assert_parse(
      {
        "rubyDefine" => [[1, 1, 3]],
        "Keyword" => [[2, 1, 3]],
        "rubyFunction" => [[1, 10, 3]],
      }, <<~RUBY
        def self.foo
        end
      RUBY
    )
  end

  def test_def_def
    assert_parse(
      {
        "rubyDefine" => [[1, 1, 3]],
        "Keyword" => [[2, 1, 3]],
        "rubyFunction" => [[1, 5, 3]],
      }, <<~RUBY
        def def
        end
      RUBY
    )
  end

  def test_symbol_literal
    assert_parse(
      {
        "rubySymbol" => [[1, 2, 3]],
        "rubySymbolDelimiter" => [[1, 1, 1]]
      }, <<~RUBY
        :foo
      RUBY
    )
  end

  def test_symbol_with_Xvar
    assert_parse(
      {
        "rubySymbol" => [[1, 2, 4], [2, 2, 4], [3, 2, 5]],
        "rubySymbolDelimiter" => [[1, 1, 1], [2, 1, 1], [3, 1, 1]],
        # FIXME
        "rubyGlobalVariable" => [],
        "rubyInstanceVariable" => [],
        "rubyClassVariable" => [],
      }, <<~RUBY
        :$foo
        :@foo
        :@@foo
      RUBY
    )
  end
end
