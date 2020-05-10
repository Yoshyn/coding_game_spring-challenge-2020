require "minitest/autorun"
require "pry-byebug"

require_relative "../core_ext/attr_history"

class Dummy
  extend AttrHistory
  attr_historized(:value)
  def initialize(value=nil)
    self.value = value if value
  end

  def update(value)
    self.value = value
  end
end

class AttrHistoryTest < Minitest::Test

  def test_init
    dummy = Dummy.new('Yolo')
    assert_equal ['Yolo'], dummy._values
    assert_equal 'Yolo', dummy.value
    dummy.update('Yolo2')
    assert_equal ['Yolo', 'Yolo2'], dummy._values
    assert_equal 'Yolo2', dummy.value
  end

  def test_get
    dummy = Dummy.new
    assert_nil dummy.value
    assert_equal [], dummy._values
  end

  def test_set
    dummy = Dummy.new
    dummy.value = 'value'
    assert_equal 'value', dummy.value
    assert_equal ['value'], dummy._values
    dummy.value = 'value2'
    assert_equal ['value', 'value2'], dummy._values
  end

  def test_not_shared
    dummy = Dummy.new
    dummy.value = 'value'
    dummy2 = Dummy.new
    assert_nil dummy2.value
  end

  def test_changed?
    dummy = Dummy.new
    assert_equal false, dummy.value_changed?
    dummy.value = 'value'
    assert_equal false, dummy.value_changed?
    dummy.value = 'value'
    dummy.value = 'value'
    assert_equal false, dummy.value_changed?
    dummy.value = 'value2'
    assert_equal true, dummy.value_changed?
  end

  def test_already_changed?
    dummy = Dummy.new
    assert_equal false, dummy.value_already_changed?
    dummy.value = 'value2'
    dummy.value = 'value'
    dummy.value = 'value'
    assert_equal false, dummy.value_changed?
    dummy.value = 'value'
    assert_equal true, dummy.value_already_changed?
  end

  def test_already_increased?
    dummy = Dummy.new
    assert_equal false, dummy.value_increased?
    assert_equal false, dummy.value_decreased?
    dummy.value = 1
    assert_equal false, dummy.value_increased?
    assert_equal false, dummy.value_decreased?
    dummy.value = 1
    assert_equal false, dummy.value_increased?
    assert_equal false, dummy.value_decreased?
    dummy.value = 2
    assert_equal true, dummy.value_increased?
    assert_equal false, dummy.value_decreased?
    dummy.value = 1
    assert_equal true, dummy.value_decreased?
    assert_equal false, dummy.value_increased?
  end

  def test_previous_value
    dummy = Dummy.new
    assert_nil dummy.previous_value
    dummy.value = 'value'
    assert_nil dummy.previous_value
    dummy.value = 'value2'
    assert_equal 'value', dummy.previous_value
    dummy.value = 'value3'
    assert_equal 'value2', dummy.previous_value
  end
end
