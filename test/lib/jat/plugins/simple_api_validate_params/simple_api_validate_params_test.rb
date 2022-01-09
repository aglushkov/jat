# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::SimpleApiValidateParams" do
  before do
    @plugin = Jat::Plugins.find_plugin(:simple_api_validate_params)
  end

  it "checks simple_api plugin loaded before" do
    jat_class = Class.new(Jat)
    error = assert_raises(Jat::Error) { jat_class.plugin @plugin }
    assert_match(/simple_api/, error.message)
  end

  let(:base_serializer) do
    jat_class = Class.new(Jat)
    jat_class.plugin :simple_api
    jat_class.plugin @plugin
    jat_class
  end

  let(:serializer) do
    jat_class = Class.new(base_serializer)
    jat_class.attribute :foo_bar
    jat_class.relationship :foo_bazz, serializer: jat_class
    jat_class
  end

  let(:serializer_lower_camel_case) do
    jat_class = Class.new(base_serializer)
    jat_class.plugin :lower_camel_case

    jat_class.attribute :foo_bar
    jat_class.relationship :foo_bazz, serializer: jat_class
    jat_class
  end

  it "returns true when provided fields present" do
    jat = serializer.new(fields: "foo_bar,foo_bazz(foo_bar)")
    assert jat.validate
  end

  it "validates fields" do
    jat = serializer.new(fields: "foo_bar,extra")
    error = assert_raises(Jat::SimpleApiFieldsError) { jat.validate }
    expected_message = "Field 'extra' not exists"
    assert_equal(expected_message, error.message)
  end

  it "validates fields when using lower_camel_case plugin" do
    jat = serializer_lower_camel_case.new(fields: "fooBar,extra")
    error = assert_raises(Jat::SimpleApiFieldsError) { jat.validate }
    expected_message = "Field 'extra' not exists"
    assert_equal(expected_message, error.message)
  end

  it "validates deeply nested fields" do
    c = Class.new(base_serializer)
    c.attribute :c1
    c.attribute :c2

    b = Class.new(base_serializer)
    b.attribute :b1
    b.attribute :b2
    b.relationship :c, serializer: c

    a = Class.new(base_serializer)
    a.attribute :a1
    a.attribute :a2
    a.relationship :b, serializer: b
    a.relationship :c, serializer: c

    jat = a.new(fields: "a1,a2,c(c1,c2),b(b1,b2,c(c1,c2,c3)")
    error = assert_raises(Jat::SimpleApiFieldsError) { jat.validate }
    expected_message = "Field 'c3' ('b.c.c3') not exists"
    assert_equal(expected_message, error.message)
  end

  it "validates deeply nested fields about not existing relationship" do
    c = Class.new(base_serializer)
    c.attribute :c1
    c.attribute :c2

    b = Class.new(base_serializer)
    b.attribute :b1
    b.attribute :b2
    b.relationship :c, serializer: c

    a = Class.new(base_serializer)
    a.attribute :a1
    a.attribute :a2
    a.relationship :b, serializer: b
    a.relationship :c, serializer: c

    jat = a.new(fields: "a1,a2,c(c1,c2),b(b1,b2,c(c1,c2(c3))")
    error = assert_raises(Jat::SimpleApiFieldsError) { jat.validate }
    expected_message = "Field 'c2' ('b.c.c2') is not a relationship to add 'c3' attribute"
    assert_equal(expected_message, error.message)
  end
end
