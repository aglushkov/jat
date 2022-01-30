# frozen_string_literal: true

require "test_helper"

describe Jat::Config do
  let(:jat_class) { Class.new(Jat) }
  let(:config) { jat_class.config }

  describe ".jat_class=" do
    it "assigns @jat_class" do
      config.class.jat_class = :foo
      assert_equal :foo, config.class.instance_variable_get(:@jat_class)
    end
  end

  describe ".jat_class" do
    it "returns self @jat_class" do
      assert_same jat_class, config.class.instance_variable_get(:@jat_class)
      assert_same jat_class, config.class.jat_class
    end
  end

  describe "#initialize" do
    it "deeply copies provided opts" do
      opts = {foo: {bar: {bazz: :bazz2}}}

      config = Jat::Config.new(opts)
      assert_equal config.opts, opts
      refute_same config.opts[:foo], opts[:foo]
      refute_same config.opts[:foo][:bar], opts[:foo][:bar]
    end
  end

  describe "#[]=" do
    it "adds options" do
      config = Jat::Config.new
      config[:foo] = :bar

      assert_equal :bar, config.opts[:foo]
    end
  end

  describe "#[]" do
    it "reads options" do
      config = Jat::Config.new
      config[:foo] = :bar

      assert_equal :bar, config[:foo]
    end
  end
end
