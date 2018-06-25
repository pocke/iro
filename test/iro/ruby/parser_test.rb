require 'test_helper'

class TestIroRubyParser < Minitest::Test
  include UnificationAssertion

  def assert_parse(expected, source)
    got = Iro::Ruby::Parser.tokens(source)
    got.each do |_key, value|
      value.sort!
    end
    assert_unifiable(expected, got)
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

  def test_tokens_qwords_beg
    assert_parse(
      {
        'Delimiter' => [[1,1,3], [1,7,1]],
        'String' => [[1,4,3]]
      }, <<~RUBY
        %w[foo]
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
        'rubySymbol' => [[1, 2, 3], [2, 7, 3]],
        'rubyDefine' => [[2, 1, 3], [3, 1, 3]],
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
        "rubyDefine" => [[1, 1, 3], [2, 1, 3]],
        "rubyFunction" => [[1, 5, 3]],
      }, <<~RUBY
        def foo
        end
      RUBY
    )
  end

  def test_boolean
    assert_parse(
      {
        'Keyword' => [[1, 1, 4], [2, 1, 5]],
      }, <<~RUBY
        true
        false
      RUBY
    )
  end

  def test_defs
    assert_parse(
      {
        "rubyDefine" => [[1, 1, 3], [2, 1, 3]],
        "Keyword" => [[1, 5, 4]],
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
        "rubyDefine" => [[1, 1, 3], [2, 1, 3]],
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

  def test_const
    assert_parse(
      {
        "Type" => [[1, 1, 3], [2, 3, 3], [3, 5, 3], [4, 3, 3], [4, 8, 3],
                   [6, 7, 1], [8, 8, 3], [10, 7, 3], [10, 13, 3], [12, 7, 3], [12, 12, 6],
                   [18, 1, 3], [18, 6, 3]],
        "rubySymbol" => :_,
        "Keyword" => :_,
        "rubyDefine" => :_,
        "rubyFunction" => :_,
        "rubySymbolDelimiter" => :_,
      }, <<~RUBY
        Foo = _
        p Foo
        p ::Foo
        p Foo::Bar

        class A
        end
        module Abc
        end
        class Foo < Bar
        end
        class Foo::FooBar
        end

        p :Foo
        Foo()
        def Foo() end
        Foo::Bar = _
      RUBY
    )
  end

  def test_keyword_like_method
    assert_parse(
      {
        "Keyword" => [[1, 1, 7], [2, 1, 6], [3, 1, 5]]
      }, <<~RUBY
        private foo
        public(foo)
        raise
        bar.private(foo)
      RUBY
    )
  end

  def test_end
    assert_parse(
      {
        'Keyword' => [
          [1, 1, 5], # class
          [2, 3, 6], [2, 13, 3], # module end
          [4, 5, 5], # begin
          [6, 5, 3], # end
          [8, 9, 2], # do
          [9, 5, 3], # end
          [11, 5, 3], [11, 11, 2], [11, 16, 2], # for in do
          [12, 5, 3], # end
          [13, 5, 3], [13, 11, 2], # for in
          [14, 5, 3], # end
          [16, 5, 5], [16, 13, 2], # while do
          [17, 5, 3], # end
          [18, 7, 5], # while
          [19, 5, 5], # begin
          [21, 5, 3], [21, 9, 5], # end while
          [22, 5, 5], # until
          [23, 5, 3], # end
          [24, 7, 5], # until
          [26, 5, 4], # case
          [27, 5, 4], # when
          [28, 5, 4], # else
          [29, 5, 3], # end
          [31, 5, 2], # if
          [32, 11, 2], # modifier if
          [33, 7, 6], # unless
          [34, 13, 6], # modifier unless
          [35, 7, 3], # end
          [36, 5, 3], # end
          [38, 1, 3], # end
        ],
        'rubyDefine' => [
          [3, 3, 3], # def
          [37, 3, 3] # end
        ],
        'Type' => :_,
        'rubyFunction' => :_,
      }, <<~RUBY
        class A
          module B; end
          def foo
            begin
              foo
            end

            tap do
            end

            for _ in a do
            end
            for _ in a
            end

            while c do
            end
            a while b
            begin
              foo
            end while c
            until c
            end
            a until c

            case a
            when b
            else c
            end

            if cond
              baz if bar
              unless cond
                foo unless c
              end
            end
          end
        end
      RUBY
    )
  end
end
