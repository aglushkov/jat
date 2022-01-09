# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApiLowerCamelCase" do
  let(:jat_class) do
    new_class = Class.new(Jat)
    new_class.plugin(:json_api)
    new_class.plugin(:json_api_lower_camel_case)
    new_class
  end

  before do
    jat_class.type :foo
    jat_class.id { |object| object }
  end

  it "checks json_api plugin loaded before" do
    jat_class = Class.new(Jat)
    error = assert_raises(Jat::Error) { jat_class.plugin :json_api_lower_camel_case }
    assert_match(/json_api/, error.message)
  end

  it "returns attributes in lowerCamelCase case" do
    jat_class.attribute(:foo_bar) { 1 }

    assert_equal({fooBar: 1}, jat_class.to_h(true).dig(:data, :attributes))
  end

  it "accepts `fields` in lowerCamelCase format" do
    jat_class.attribute(:foo_bar, exposed: false) { 1 }

    response = jat_class.to_h(true, fields: {foo: "fooBar"})
    assert_equal({fooBar: 1}, response.dig(:data, :attributes))
  end

  it "accepts `include` in lowerCamelCase format" do
    new_serializer = Class.new(Jat)
    new_serializer.plugin(:json_api)
    new_serializer.type :new
    new_serializer.id { |object| object }

    jat_class.relationship(:foo_bar, serializer: new_serializer) { 1 }

    response = jat_class.to_h(true, include: "fooBar")
    response_relationships = response.dig(:data, :relationships).keys
    assert_includes(response_relationships, :fooBar)
  end

  it "returns document meta keys in lowerCamelCase format" do
    jat_class.document_meta(:user_agent) { "Firefox" }

    response = jat_class.to_h(nil)
    assert_equal({meta: {userAgent: "Firefox"}}, response)
  end

  it "returns document jsonapi keys in lowerCamelCase format" do
    jat_class.jsonapi(:user_agent) { "Firefox" }

    response = jat_class.to_h(nil)
    assert_equal({jsonapi: {userAgent: "Firefox"}}, response)
  end

  it "returns document links keys in lowerCamelCase format" do
    jat_class.document_link(:user_agent) { "Firefox" }

    response = jat_class.to_h(nil)
    assert_equal({links: {userAgent: "Firefox"}}, response)
  end

  it "returns context meta keys in lowerCamelCase format" do
    response = jat_class.to_h(nil, meta: {user_agent: "Chrome"})
    assert_equal({meta: {userAgent: "Chrome"}}, response)
  end

  it "returns context jsonapi keys in lowerCamelCase format" do
    response = jat_class.to_h(nil, jsonapi: {user_agent: "Chrome"})
    assert_equal({jsonapi: {userAgent: "Chrome"}}, response)
  end

  it "returns context links keys in lowerCamelCase format" do
    response = jat_class.to_h(nil, links: {user_agent: "Chrome"})
    assert_equal({links: {userAgent: "Chrome"}}, response)
  end
end
