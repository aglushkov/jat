# frozen_string_literal: true

require "test_helper"

describe Jat::Presenter do
  let(:jat_class) { Class.new(Jat) }
  let(:presenter_class) { jat_class::Presenter }

  describe ".jat_class=" do
    it "assigns @jat_class" do
      presenter_class.jat_class = :foo
      assert_equal :foo, presenter_class.instance_variable_get(:@jat_class)
    end
  end

  describe ".jat_class" do
    it "returns self @jat_class" do
      assert_same jat_class, presenter_class.instance_variable_get(:@jat_class)
      assert_same jat_class, presenter_class.jat_class
    end
  end

  describe ".inspect" do
    it "returns self name" do
      assert_equal "#{jat_class}::Presenter", presenter_class.inspect
    end
  end

  describe ".add_method" do
    let(:presenter) { presenter_class.new("OBJECT", "CONTEXT") }

    it "adds method by providing block without variables" do
      presenter_class.add_method(:foo, proc { [object, context] })
      assert_equal %w[OBJECT CONTEXT], presenter.foo
    end

    it "adds method by providing block with one variables" do
      presenter_class.add_method(:foo, proc { |obj| [obj, object, context] })
      assert_equal %w[OBJECT OBJECT CONTEXT], presenter.foo
    end

    it "adds method by providing block with two variables" do
      presenter_class.add_method(:foo, proc { |obj, ctx| [obj, ctx, object, context] })
      assert_equal %w[OBJECT CONTEXT OBJECT CONTEXT], presenter.foo
    end

    it "raises error when block has more than two variables" do
      error = assert_raises(Jat::Error) { presenter_class.add_method(:foo, proc { |_a, _b, _c| nil }) }
      assert_equal "Invalid block arguments count", error.message
    end
  end

  describe "#initialize" do
    it "initializes object presenter with provided object and context" do
      presenter = presenter_class.new("OBJ", "CTX")

      assert_equal "OBJ", presenter.object
      assert_equal "CTX", presenter.context
    end
  end
end
