require 'test_helper'

class TestIroRipperWrapper < Minitest::Test
  using Iro::RipperWrapper

  def expr(ruby)
    Ripper.sexp(ruby)[1][0]
  end

  def test_type
    sexp = expr('foo.bar')
    assert_equal :call, sexp.type
    sexp = expr('[1,2,3]')
    assert_equal :array, sexp.type
    sexp = expr('1')
    assert_equal :@int, sexp.type
  end

  def test_children
    sexp = expr('[1,2,3]')
    assert_equal [[:@int, "1", [1, 1]], [:@int, "2", [1, 3]], [:@int, "3", [1, 5]]], sexp.children
  end

  def test_content
    sexp = expr('1234')
    assert_equal "1234", sexp.content
  end

  def test_position
    sexp = expr("\n 1234 ")
    assert_equal [2, 1], sexp.position
  end

  def test_node?
    sexp = expr("foo.bar")
    assert sexp.node?

    sexp = expr("1234")
    refute sexp.position.node?
  end

  # XXX: Is it correct?
  def test_parser_event?
    sexp = expr("foo.bar")
    assert sexp.parser_event?

    sexp = expr("1")
    refute sexp.parser_event?
  end

  # XXX: Is it correct?
  def test_scanner_event?
    sexp = expr("1")
    assert sexp.scanner_event?

    sexp = expr("foo.bar")
    refute sexp.scanner_event?
  end

  def test_XXX_type?
    sexp = expr('foo.bar')
    assert sexp.call_type?
    refute sexp.vcall_type?

    sexp = expr('123')
    assert sexp.int_type?
    refute sexp.float_type?
  end
end
