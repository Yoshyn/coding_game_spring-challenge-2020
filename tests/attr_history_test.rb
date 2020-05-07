require "minitest/autorun"
require "pry-byebug"

require_relative "../core_ext/attr_history"

class Dummy
  extend AttrHistory
  attr_historized(:sample)
end

class AttrHistoryTest < Minitest::Test

  def test_get
    dummy = Dummy.new
    assert_nil dummy.sample
    assert_equal [], dummy._samples
  end

  def test_set
    dummy = Dummy.new
    dummy.sample = 'value'
    assert_equal 'value', dummy.sample
    assert_equal ['value'], dummy._samples
    dummy.sample = 'value2'
    assert_equal ['value', 'value2'], dummy._samples
  end


  def test_not_shared
    dummy = Dummy.new
    dummy.sample = 'value'
    dummy2 = Dummy.new
    assert_nil dummy2.sample
  end

  def test_changed?
    dummy = Dummy.new
    assert_equal false, dummy.sample_changed?
    dummy.sample = 'value'
    assert_equal false, dummy.sample_changed?
    dummy.sample = 'value'
    dummy.sample = 'value'
    assert_equal false, dummy.sample_changed?
    dummy.sample = 'value2'
    assert_equal true, dummy.sample_changed?
  end

  def test_already_changed?
    dummy = Dummy.new
    assert_equal false, dummy.sample_already_changed?
    dummy.sample = 'value2'
    dummy.sample = 'value'
    dummy.sample = 'value'
    assert_equal false, dummy.sample_changed?
    dummy.sample = 'value'
    assert_equal true, dummy.sample_already_changed?
  end

  def test_already_increased?
    dummy = Dummy.new
    assert_equal false, dummy.sample_increased?
    assert_equal false, dummy.sample_decreased?
    dummy.sample = 1
    assert_equal false, dummy.sample_increased?
    assert_equal false, dummy.sample_decreased?
    dummy.sample = 1
    assert_equal false, dummy.sample_increased?
    assert_equal false, dummy.sample_decreased?
    dummy.sample = 2
    assert_equal true, dummy.sample_increased?
    assert_equal false, dummy.sample_decreased?
    dummy.sample = 1
    assert_equal true, dummy.sample_decreased?
    assert_equal false, dummy.sample_increased?
  end
end
