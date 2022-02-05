# frozen_string_literal: true

require "test_helper"

describe Jat do
  let(:serializer_class) { Class.new(Jat) }

  describe ".plugin" do
    it "loads same plugin only once" do
      plugin = Module.new
      serializer_class.plugin plugin
      serializer_class.plugin plugin

      assert_equal [plugin], serializer_class.config[:plugins]
    end
  end

  describe ".plugin_used?" do
    it "tells if plugin has been already used in current serializer" do
      assert_equal false, serializer_class.plugin_used?(:json_api)
      serializer_class.plugin(:json_api)
      assert_equal true, serializer_class.plugin_used?(:json_api)
    end

    it "accepts Module" do
      plugin = Module.new

      assert_equal false, serializer_class.plugin_used?(plugin)
      serializer_class.plugin(plugin)
      assert_equal true, serializer_class.plugin_used?(plugin)
    end
  end

  describe ".config" do
    it "returns config object with default values" do
      config = serializer_class.config
      assert_equal serializer_class::Config, config.class
      assert_equal({plugins: []}, config.opts)
    end
  end

  describe ".inherited" do
    let(:parent) { serializer_class }

    it "inherits config class with same options" do
      parent.config[:foo] = :bar
      child = Class.new(parent)

      assert_equal parent::Config, child::Config.superclass
      assert_equal :bar, child.config[:foo]
    end

    it "inherits attributes" do
      parent.attribute(:foo) { :bar }
      child = Class.new(parent)

      assert_equal parent::Attribute, child::Attribute.superclass
      assert child.attributes[:foo]
    end
  end

  describe ".to_h" do
    let(:jat) { serializer_class.allocate }

    it "raises error that we should add some response generation plugin" do
      error = assert_raises(Jat::Error) { serializer_class.to_h(nil) }

      error_message = "Method #to_h must be implemented by plugin"
      assert_equal error_message, error.message
    end

    it "initializes serializer instance with provided context" do
      jat.expects(:to_h).with("obj")
      serializer_class.expects(:new).with("context").returns(jat)
      serializer_class.to_h("obj", "context")
    end

    it "adds empty hash context when context not provided" do
      jat.expects(:to_h).with("obj")
      serializer_class.expects(:new).with({}).returns(jat)
      serializer_class.to_h("obj")
    end
  end

  describe ".attributes" do
    it "initializes new attributes hash" do
      assert_equal({}, serializer_class.attributes)
      assert_same serializer_class.attributes, serializer_class.instance_variable_get(:@attributes)
    end
  end

  describe ".attribute" do
    it "adds new attribute to attributes hash" do
      attribute = serializer_class.attribute :foo
      assert_equal serializer_class.attributes[:foo], attribute
    end
  end

  describe ".relationship" do
    it "forces using of :serializer option" do
      error = assert_raises(ArgumentError) { serializer_class.relationship(:foo) }
      assert_match "serializer", error.message
    end

    it "adds new attribute" do
      serializer_class.relationship(:foo, serializer: serializer_class)

      attribute = serializer_class.attributes[:foo]
      assert_equal serializer_class, attribute.serializer
    end
  end

  describe "#initialize" do
    it "initializes context" do
      jat = serializer_class.new("context")
      assert_equal "context", jat.context
    end
  end

  describe "#to_h" do
    it "raises error" do
      jat = serializer_class.new

      error = assert_raises(Jat::Error) { jat.to_h(nil) }
      error_message = "Method #to_h must be implemented by plugin"
      assert_equal error_message, error.message
    end
  end
end
