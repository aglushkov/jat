# frozen_string_literal: true

require "test_helper"

describe Jat do
  let(:jat_class) { Class.new(Jat) }

  describe ".config" do
    it "returns config object" do
      config = jat_class.config
      assert_equal jat_class::Config, config.class
    end
  end

  describe ".inherited" do
    let(:parent) { jat_class }

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

    it "inherits presenter" do
      child = Class.new(parent)
      assert_equal parent::Presenter, child::Presenter.superclass
    end
  end

  describe ".call" do
    it "returns self" do
      assert_equal jat_class, jat_class.call
    end
  end

  describe ".to_h" do
    it "raises error that we should add some response generation plugin" do
      error = assert_raises(Jat::Error) { jat_class.to_h(nil) }

      error_message = "Method #to_h must be implemented by plugin"
      assert_equal error_message, error.message
    end

    it "initializes serializer instance with provided attributes" do
      jat_class.expects(:new).with("obj", "context")
      jat_class.to_h("obj", "context")
    end

    it "adds empty hash context when context not provided" do
      jat_class.expects(:new).with("obj", {})
      jat_class.to_h("obj")
    end
  end

  describe ".attributes" do
    it "initializes new attributes hash" do
      assert_equal({}, jat_class.attributes)
      assert_same jat_class.attributes, jat_class.instance_variable_get(:@attributes)
    end
  end

  describe ".attribute" do
    it "adds new attribute to attributes hash" do
      attribute = jat_class.attribute :foo
      assert_equal jat_class.attributes[:foo], attribute
    end

    it "adds method to Presenter class" do
      jat_class.attribute :foo
      assert jat_class::Presenter.method_defined?(:foo)
    end
  end

  describe "#initialize" do
    it "initializes object and context attributes" do
      jat = jat_class.new("obj", "context")

      assert_equal "obj", jat.object
      assert_equal "context", jat.context
    end
  end

  describe "#to_h" do
    it "raises error" do
      jat = jat_class.new(nil, nil)

      error = assert_raises(Jat::Error) { jat.to_h }
      error_message = "Method #to_h must be implemented by plugin"
      assert_equal error_message, error.message
    end
  end

  describe "#config" do
    it "returns self class config" do
      jat = jat_class.new(nil, nil)

      assert_same jat.config, jat_class.config
    end
  end
end
