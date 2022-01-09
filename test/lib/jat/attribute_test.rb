# frozen_string_literal: true

require "test_helper"

describe Jat::Attribute do
  let(:jat_class) { Class.new(Jat) }
  let(:attribute_class) { jat_class::Attribute }

  describe ".jat_class=" do
    it "assigns @jat_class" do
      attribute_class.jat_class = :foo
      assert_equal :foo, attribute_class.instance_variable_get(:@jat_class)
    end
  end

  describe ".jat_class" do
    it "returns self @jat_class" do
      assert_same jat_class, attribute_class.instance_variable_get(:@jat_class)
      assert_same jat_class, attribute_class.jat_class
    end
  end

  describe ".inspect" do
    it "returns self name" do
      assert_equal "#{jat_class}::Attribute", attribute_class.inspect
    end
  end

  describe "#initialize" do
    it "deeply copies provided params" do
      params = {name: :foo, opts: {include: {foo: :bar}}, block: -> {}}

      attribute = attribute_class.new(**params)
      assert_equal attribute.params, params
      refute_same attribute.params, params
      refute_same attribute.opts, params[:opts]
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
      jat_class.config[:exposed] = :all
      attribute = attribute_class.new(name: "foo")
      assert_equal true, attribute.exposed?
    end

    it "returns false when no keys are exposed by config" do
      jat_class.config[:exposed] = :none
      attribute = attribute_class.new(name: "foo")
      assert_equal false, attribute.exposed?
    end

    it "returns false when serializer exists and config[:exposed] is default" do
      jat_class.config[:exposed] = :default
      attribute = attribute_class.new(name: "foo", opts: {serializer: jat_class})
      assert_equal false, attribute.exposed?
    end

    it "returns true when serializer not exists and config[:exposed] is default" do
      jat_class.config[:exposed] = :default
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
      attribute = attribute_class.new(name: "foo", opts: {serializer: jat_class})
      assert_equal true, attribute.relation?
    end
  end

  describe "#serializer" do
    it "returns nil when no serializer key" do
      attribute = attribute_class.new(name: "foo")
      assert_nil attribute.serializer
    end

    it "returns provided serializer" do
      attribute = attribute_class.new(name: "foo", opts: {serializer: jat_class})
      assert_same jat_class, attribute.serializer
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
      jat_class.attribute(:foo) {}
      jat_class.attribute(:foo) { |_| }
      jat_class.attribute(:foo) { |_, _| }
      err = assert_raises(Jat::Error) { jat_class.attribute(:foo) { |_, _, _| } }
      assert_equal "Block can have 0-2 parameters", err.message
    end
  end
end
