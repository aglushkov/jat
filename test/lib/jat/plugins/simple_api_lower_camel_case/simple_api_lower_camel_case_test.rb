# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::SimpleApiLowerCamelCase" do
  let(:jat_class) do
    new_class = Class.new(Jat)
    new_class.plugin(:simple_api)
    new_class.plugin(:simple_api_lower_camel_case)
    new_class
  end

  it "checks simple_api plugin loaded before" do
    jat_class = Class.new(Jat)
    error = assert_raises(Jat::Error) { jat_class.plugin :simple_api_lower_camel_case }
    assert_match(/simple_api/, error.message)
  end

  it "loads _lower_camel_case plugin" do
    assert jat_class.plugin_used?(:base_lower_camel_case)
  end

  it "returns attributes in lowerCamelCase case" do
    jat_class.attribute(:foo_bar) { 1 }

    response = jat_class.to_h(true)
    assert_equal({fooBar: 1}, response)
  end

  it "accepts fields in lowerCamelCase format" do
    jat_class.attribute(:foo_bar, exposed: false) { 1 }

    response = jat_class.to_h(true, fields: "fooBar")
    assert_equal({fooBar: 1}, response)
  end

  it "returns meta keys in lowerCamelCase format" do
    jat_class.meta(:user_agent) { "Firefox" }

    response = jat_class.to_h(nil)
    assert_equal({meta: {userAgent: "Firefox"}}, response)
  end

  it "returns context meta keys in lowerCamelCase format" do
    response = jat_class.to_h(nil, meta: {user_agent: "Firefox"})
    assert_equal({meta: {userAgent: "Firefox"}}, response)
  end

  it "joins meta in lowerCamelCase format" do
    jat_class.meta(:userAgent) { "Firefox" }
    response = jat_class.to_h(nil, meta: {user_agent: "Firefox 2.0"})
    assert_equal({meta: {userAgent: "Firefox 2.0"}}, response)
  end
end
