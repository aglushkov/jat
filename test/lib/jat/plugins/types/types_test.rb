# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::Types" do
  let(:struct) { Struct.new(:attr) }

  let(:jat_class) do
    new_class = Class.new(Jat)
    new_class.plugin(:types)
    new_class
  end

  def attr_value(original_value)
    obj = struct.new(original_value)
    jat_class.attributes[:attr].value(obj, nil)
  end

  it "has predefined :int type" do
    jat_class.attribute(:attr, type: :int)

    assert_equal(0, attr_value("0"))
    assert_equal(8, attr_value("010")) # octal system
    assert_equal(10, attr_value("0xa")) # hexadecimal system
  end

  it "has predefined :bool type" do
    jat_class.attribute(:attr, type: :bool)

    assert_equal(false, attr_value(nil))
    assert_equal(false, attr_value(false))
    assert_equal(true, attr_value(1))
  end

  it "has predefined :float type" do
    jat_class.attribute(:attr, type: :float)

    assert_same(0.0, attr_value("0"))
    assert_same(0.001, attr_value("1e-3"))
    assert_same(1.234, attr_value("1.234"))
  end

  it "has predefined :array type" do
    jat_class.attribute(:attr, type: :array)

    assert_equal([1], attr_value(1))
    assert_equal([1], attr_value([1]))
  end

  it "has predefined :hash type" do
    jat_class.attribute(:attr, type: :hash)

    assert_equal({}, attr_value([]))
    assert_equal({}, attr_value({}))
    assert_equal({key: :value}, attr_value(key: :value))
  end

  it "has predefined :str type" do
    jat_class.attribute(:attr, type: :str)

    assert_equal("", attr_value(nil))
    assert_equal("123", attr_value(123))
  end

  it "allows to use callable method as type" do
    jat_class.attribute(:attr, type: ->(obj) { obj ? :yes : :no })

    assert_equal(:no, attr_value(nil))
    assert_equal(:yes, attr_value(1))
  end

  it "allows to configure custom type" do
    jat_class.config[:types][:year] = ->(obj) { obj.strftime("%Y") }
    jat_class.attribute(:attr, type: :year)

    assert_equal("2020", attr_value(Time.new(2020, 10, 10)))
  end

  it "allows to skip type" do
    jat_class.attribute(:attr)
    assert_equal(333, attr_value(333))
  end
end
