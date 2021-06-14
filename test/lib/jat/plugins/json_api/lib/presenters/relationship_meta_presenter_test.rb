# frozen_string_literal: true

require "test_helper"

describe "Jat::Presenters::RelationshipMetaPresenter" do
  before { Jat::Plugins.load_plugin(:json_api) }

  let(:jat_class) { Class.new(Jat) { plugin :json_api } }
  let(:presenter_class) { jat_class::RelationshipMetaPresenter }

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
      assert_equal "#{jat_class}::Presenters::RelationshipMetaPresenter", presenter_class.inspect
    end
  end

  describe ".add_method" do
    let(:presenter) { presenter_class.new("PARENT_OBJECT", "OBJECT", "CONTEXT") }

    it "adds method by providing block without variables" do
      presenter_class.add_method(:foo, proc { [parent_object, object, context] })
      assert_equal %w[PARENT_OBJECT OBJECT CONTEXT], presenter.foo
    end

    it "adds method by providing block with one variables" do
      presenter_class.add_method(:foo, proc { |parent_obj| [parent_obj, parent_object, object, context] })
      assert_equal %w[PARENT_OBJECT PARENT_OBJECT OBJECT CONTEXT], presenter.foo
    end

    it "adds method by providing block with two variables" do
      presenter_class.add_method(:foo, proc { |parent_obj, obj| [parent_obj, parent_object, obj, object, context] })
      assert_equal %w[PARENT_OBJECT PARENT_OBJECT OBJECT OBJECT CONTEXT], presenter.foo
    end

    it "adds method by providing block with three variables" do
      presenter_class.add_method(:foo, proc { |parent_obj, obj, ctx| [parent_obj, parent_object, obj, object, ctx, context] })
      assert_equal %w[PARENT_OBJECT PARENT_OBJECT OBJECT OBJECT CONTEXT CONTEXT], presenter.foo
    end

    it "raises error when block has more than three variables" do
      error = assert_raises(Jat::Error) { presenter_class.add_method(:foo, proc { |_a, _b, _c, _d| }) }
      assert_equal "Invalid block arguments count", error.message
    end

    it "redefines_method" do
      presenter_class.add_method(:foo, proc { "OLD" })
      presenter_class.add_method(:foo, proc { "NEW" })
      assert_equal "NEW", presenter.foo
    end
  end

  describe "#initialize" do
    it "initializes object presenter with provided object and context" do
      presenter = presenter_class.new("PARENT", "OBJ", "CTX")

      assert_equal "PARENT", presenter.parent_object
      assert_equal "OBJ", presenter.object
      assert_equal "CTX", presenter.context
    end
  end
end
