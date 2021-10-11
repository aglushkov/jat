# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApiValidateParams" do
  before do
    @plugin = Jat::Plugins.find_plugin(:json_api_validate_params)
  end

  it "checks json_api plugin loaded before" do
    jat_class = Class.new(Jat)
    error = assert_raises(Jat::Error) { jat_class.plugin @plugin }
    assert_match(/json_api/, error.message)
  end

  let(:serializer) do
    jat_class = Class.new(Jat)
    jat_class.plugin :json_api
    jat_class.plugin @plugin

    jat_class.type "foo"
    jat_class.attribute :foo_bar
    jat_class.relationship :foo_bazz, serializer: jat_class
    jat_class
  end

  let(:serializer_camel_lower) do
    jat_class = Class.new(Jat)
    jat_class.plugin :json_api
    jat_class.plugin @plugin
    jat_class.plugin :camel_lower

    jat_class.type "foo"
    jat_class.attribute :foo_bar
    jat_class.relationship :foo_bazz, serializer: jat_class
    jat_class
  end

  it "validates fields types" do
    jat = serializer.new(fields: {bar: "any"})
    error = assert_raises(Jat::JsonApiParamsError) { jat.validate }

    expected_message = "Response does not have resources with type 'bar'. Existing types are: 'foo'"
    assert_equal(expected_message, error.message)
  end

  it "validates attributes" do
    jat = serializer.new(fields: {foo: "foo_bar,foo_baz"})
    error = assert_raises(Jat::JsonApiParamsError) { jat.validate }

    expected_message = "No attribute 'foo_baz' in resource type 'foo'. Existing attributes are: 'foo_bar', 'foo_bazz'"
    assert_equal(expected_message, error.message)
  end

  it "validates attributes correctly when camel_lower plugin loaded" do
    jat = serializer_camel_lower.new(fields: {foo: "fooBar,fooBaz"})
    error = assert_raises(Jat::JsonApiParamsError) { jat.validate }

    expected_message = "No attribute 'fooBaz' in resource type 'foo'. Existing attributes are: 'fooBar', 'fooBazz'"
    assert_equal(expected_message, error.message)
  end

  it "validates includes" do
    jat = serializer.new(include: "extra")
    error = assert_raises(Jat::JsonApiParamsError) { jat.validate }
    expected_message = "Type 'foo' has no included 'extra' relationship. Existing relationships are: 'foo_bazz'"
    assert_equal(expected_message, error.message)
  end

  it "validates includes when parameter named as existing attribute (not relationship)" do
    jat = serializer.new(include: "foo_bar")
    error = assert_raises(Jat::JsonApiParamsError) { jat.validate }
    expected_message = "Type 'foo' has no included 'foo_bar' relationship. Existing relationships are: 'foo_bazz'"
    assert_equal(expected_message, error.message)
  end

  it "validates includes correctly when camel_lower plugin loaded" do
    jat = serializer_camel_lower.new(include: "extra")
    error = assert_raises(Jat::JsonApiParamsError) { jat.validate }

    expected_message = "Type 'foo' has no included 'extra' relationship. Existing relationships are: 'fooBazz'"
    assert_equal(expected_message, error.message)
  end
end