# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::CamelLower" do
  let(:jat_class) do
    new_class = Class.new(Jat)
    new_class.plugin(:camel_lower)
    new_class
  end

  describe "Attribute" do
    describe "#name" do
      it "returns name in camel_lower case" do
        attribute = jat_class.attribute(:foo)
        assert :foo, attribute.name

        attribute = jat_class.attribute(:foo_bar)
        assert :fooBar, attribute.name

        attribute = jat_class.attribute(:foo_bar_bazz)
        assert :fooBarBazz, attribute.name
      end
    end
  end

  describe "Test responses with simple_api plugin" do
    before { jat_class.plugin(:simple_api) }

    it "returns attributes in camelLower case" do
      jat_class.attribute(:foo_bar) { 1 }

      response = jat_class.to_h(true)
      assert_equal({fooBar: 1}, response)
    end

    it "accepts fields in camelLower format" do
      jat_class.attribute(:foo_bar, exposed: false) { 1 }

      response = jat_class.to_h(true, fields: "fooBar")
      assert_equal({fooBar: 1}, response)
    end

    it "returns meta keys in camelLower format" do
      jat_class.meta(:user_agent) { "Firefox" }

      response = jat_class.to_h(nil)
      assert_equal({meta: {userAgent: "Firefox"}}, response)
    end

    it "returns context meta keys in camelLower format" do
      response = jat_class.to_h(nil, meta: {user_agent: "Firefox"})
      assert_equal({meta: {userAgent: "Firefox"}}, response)
    end

    it "joins meta in camelLower format" do
      jat_class.meta(:userAgent) { "Firefox" }
      response = jat_class.to_h(nil, meta: {user_agent: "Firefox 2.0"})
      assert_equal({meta: {userAgent: "Firefox 2.0"}}, response)
    end
  end

  describe "Test responses with json_api plugin" do
    before do
      jat_class.plugin(:json_api)
      jat_class.type :foo
      jat_class.id { |object| object }
    end

    it "returns attributes in camelLower case" do
      jat_class.attribute(:foo_bar) { 1 }

      assert_equal({fooBar: 1}, jat_class.to_h(true).dig(:data, :attributes))
    end

    it "accepts `fields` in camelLower format" do
      jat_class.attribute(:foo_bar, exposed: false) { 1 }

      response = jat_class.to_h(true, fields: {foo: "fooBar"})
      assert_equal({fooBar: 1}, response.dig(:data, :attributes))
    end

    it "accepts `include` in camelLower format" do
      new_serializer = Class.new(Jat)
      new_serializer.plugin(:json_api)
      new_serializer.type :new
      new_serializer.id { |object| object }

      jat_class.relationship(:foo_bar, serializer: new_serializer) { 1 }

      response = jat_class.to_h(true, include: "fooBar")
      response_relationships = response.dig(:data, :relationships).keys
      assert_includes(response_relationships, :fooBar)
    end
  end
end
