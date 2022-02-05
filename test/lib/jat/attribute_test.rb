# frozen_string_literal: true

require "test_helper"

describe Jat::Attribute do
  let(:serializer_class) { Class.new(Jat) }
  let(:attribute_class) { serializer_class::Attribute }

  describe ".serializer_class=" do
    it "assigns @serializer_class" do
      attribute_class.serializer_class = :foo
      assert_equal :foo, attribute_class.instance_variable_get(:@serializer_class)
    end
  end

  describe ".serializer_class" do
    it "returns self @serializer_class" do
      assert_same serializer_class, attribute_class.instance_variable_get(:@serializer_class)
      assert_same serializer_class, attribute_class.serializer_class
    end
  end

  describe "#initialize" do
    it "deeply copies provided opts" do
      opts = {include: {foo: :bar}}
      name = :foo

      attribute = attribute_class.new(name: name, opts: opts, block: -> {})
      assert_equal attribute.opts, opts
      refute_same attribute.opts, opts
      refute_same attribute.opts[:include], opts[:include]
    end
  end

  describe "#name" do
    it "symbolizes name" do
      attribute = attribute_class.new(name: "foo")
      assert_equal :foo, attribute.name
    end
  end

  describe "#key" do
    it "returns same as #name when key not provided" do
      attribute = attribute_class.new(name: "foo")
      assert_equal :foo, attribute.key
    end

    it "returns symbolized key option" do
      attribute = attribute_class.new(name: "foo", opts: {key: "bar"})
      assert_equal :bar, attribute.key
    end
  end

  describe "#exposed?" do
    it "returns provided value" do
      attribute = attribute_class.new(name: "foo", opts: {exposed: false})
      assert_equal false, attribute.exposed?
    end

    it "returns true when all keys are exposed by config" do
      serializer_class.config[:exposed] = :all
      attribute = attribute_class.new(name: "foo")
      assert_equal true, attribute.exposed?
    end

    it "returns false when no keys are exposed by config" do
      serializer_class.config[:exposed] = :none
      attribute = attribute_class.new(name: "foo")
      assert_equal false, attribute.exposed?
    end

    it "returns false when serializer exists and config[:exposed] is default" do
      serializer_class.config[:exposed] = :default
      attribute = attribute_class.new(name: "foo", opts: {serializer: serializer_class})
      assert_equal false, attribute.exposed?
    end

    it "returns true when serializer not exists and config[:exposed] is default" do
      serializer_class.config[:exposed] = :default
      attribute = attribute_class.new(name: "foo")
      assert_equal true, attribute.exposed?
    end
  end

  describe "#many?" do
    it "returns nil when no key provided" do
      attribute = attribute_class.new(name: "foo")
      assert_nil attribute.many?
    end

    it "returns provided data" do
      attribute = attribute_class.new(name: "foo", opts: {many: false})
      assert_equal false, attribute.many?
      assert_equal false, attribute.instance_variable_get(:@many)
      assert_same attribute.instance_variable_get(:@many), attribute.many?
    end
  end

  describe "#relation?" do
    it "returns false when no serializer key" do
      attribute = attribute_class.new(name: "foo")
      assert_equal false, attribute.relation?
    end

    it "returns true with serializer key" do
      attribute = attribute_class.new(name: "foo", opts: {serializer: serializer_class})
      assert_equal true, attribute.relation?
    end
  end

  describe "#serializer" do
    it "returns nil when no serializer key" do
      attribute = attribute_class.new(name: "foo")
      assert_nil attribute.serializer
    end

    it "returns provided serializer" do
      attribute = attribute_class.new(name: "foo", opts: {serializer: serializer_class})
      assert_same serializer_class, attribute.serializer
    end
  end

  describe "#block" do
    it "returns provided block" do
      block = proc { |object, context| [object, context] }
      attribute = attribute_class.new(name: "foo", block: block)
      assert_equal ["OBJECT", "CONTEXT"], attribute.value("OBJECT", "CONTEXT")
    end

    it "returns provided block when block was without params" do
      block = proc { "RESULT" }
      attribute = attribute_class.new(name: "foo", block: block)
      assert_equal "RESULT", attribute.value("OBJECT", "CONTEXT")
    end

    it "returns provided block when block was with one param" do
      block = proc { |object| object }
      attribute = attribute_class.new(name: "foo", block: block)
      assert_equal "OBJECT", attribute.value("OBJECT", "CONTEXT")
    end

    it "constructs block that calls current key method on object" do
      attribute = attribute_class.new(name: "foo", opts: {key: :length})
      assert_equal 3, attribute.value([1, 2, 3], nil)
    end

    it "raises error if provide block with more than 2 params" do
      serializer_class.attribute(:foo) {}
      serializer_class.attribute(:foo) { |_| }
      serializer_class.attribute(:foo) { |_, _| }
      err = assert_raises(Jat::Error) { serializer_class.attribute(:foo) { |_, _, _| } }
      assert_equal "Block can have 0-2 parameters", err.message
    end
  end
end
