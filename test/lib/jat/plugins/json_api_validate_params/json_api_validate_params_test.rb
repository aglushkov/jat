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

  let(:base) do
    jat_class = Class.new(Jat)
    jat_class.plugin :json_api
    jat_class
  end

  let(:serializer) do
    jat_class = Class.new(base)
    jat_class.plugin @plugin

    jat_class.type "foo"
    jat_class.attribute :foo_bar
    jat_class.relationship :foo_bazz, serializer: foo_bazz_serializer
    jat_class
  end

  let(:foo_bazz_serializer) do
    jat_class = Class.new(base)
    jat_class.type "foo_bazz"
    jat_class.attribute :bazz
    jat_class
  end

  let(:serializer_lower_camel_case) do
    jat_class = Class.new(base)
    jat_class.plugin :json_api_lower_camel_case
    jat_class.plugin @plugin

    jat_class.type "foo"
    jat_class.attribute :foo_bar
    jat_class.relationship :foo_bazz, serializer: foo_bazz_serializer
    jat_class
  end

  it "returns true when provided fields present" do
    jat = serializer.new(fields: {foo: "foo_bar,foo_bazz", foo_bazz: "bazz"})
    assert jat.validate
  end

  it "validates fields types" do
    jat = serializer.new(fields: {bar: "any"})
    error = assert_raises(Jat::JsonApiParamsError) { jat.validate }

    expected_message = "Response does not have resources with type 'bar'. Existing types are: 'foo', 'foo_bazz'"
    assert_equal(expected_message, error.message)
  end

  it "validates attributes" do
    jat = serializer.new(fields: {foo: "foo_bar,foo_baz"})
    error = assert_raises(Jat::JsonApiParamsError) { jat.validate }

    expected_message = "No attribute 'foo_baz' in resource type 'foo'. Existing attributes are: 'foo_bar', 'foo_bazz'"
    assert_equal(expected_message, error.message)
  end

  it "validates attributes correctly when lower_camel_case plugin loaded" do
    jat = serializer_lower_camel_case.new(fields: {foo: "fooBar,fooBaz"})
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

  it "validates includes correctly when lower_camel_case plugin loaded" do
    jat = serializer_lower_camel_case.new(include: "extra")
    error = assert_raises(Jat::JsonApiParamsError) { jat.validate }

    expected_message = "Type 'foo' has no included 'extra' relationship. Existing relationships are: 'fooBazz'"
    assert_equal(expected_message, error.message)
  end

  it "validates nested includes" do
    jat = serializer.new(include: "foo_bazz.extra")
    error = assert_raises(Jat::JsonApiParamsError) { jat.validate }

    expected_message = "Type 'foo_bazz' has no included 'extra' relationship. Existing relationships are: ''"
    assert_equal(expected_message, error.message)
  end
end
