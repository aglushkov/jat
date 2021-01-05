# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::Cache" do
  let(:jat_class) do
    new_class = Class.new(Jat)
    to_h_mod = Module.new do
      def to_h
        "RES_#{object}"
      end
    end
    new_class.include(to_h_mod)
    new_class.plugin(:cache)
    new_class
  end

  let(:context) { {cache: hash_cache} }
  let(:hash_storage) { {} }
  let(:hash_cache) do
    hash_storage
    lambda do |object, context, &block|
      key = [object, context[:foo], context[:_format]].join(".").freeze
      hash_storage[key] ||= block.call
    end
  end

  describe "InstanceMethods" do
    describe "#to_h" do
      it "takes result from cache" do
        result1 = jat_class.new("OBJECT", context).to_h
        result2 = jat_class.new("OBJECT", context).to_h

        assert_equal "RES_OBJECT", result1
        assert_equal "RES_OBJECT", result2
        assert_same result1, result2
      end

      it "does not take cached result when cache keys are different" do
        result1 = jat_class.new("OBJECT", context).to_h
        result2 = jat_class.new("OBJECT", context.merge(foo: :bazz)).to_h

        assert_equal "RES_OBJECT", result1
        assert_equal "RES_OBJECT", result2
        refute_same result1, result2
      end

      it "does not saves cache when no context[:cache] provided" do
        jat_class.new("OBJECT", {}).to_str

        assert_equal [], hash_storage.keys
      end
    end

    describe "#to_str" do
      it "takes result from cache" do
        result1 = jat_class.new("OBJECT", context).to_str
        result2 = jat_class.new("OBJECT", context).to_str

        assert_equal '"RES_OBJECT"', result1
        assert_equal '"RES_OBJECT"', result2
        assert_same result1, result2
      end

      it "does not take cached result when cache keys are different" do
        result1 = jat_class.new("OBJECT", context).to_str
        result2 = jat_class.new("OBJECT", context.merge(foo: :bazz)).to_str

        assert_equal '"RES_OBJECT"', result1
        assert_equal '"RES_OBJECT"', result2
        refute_same result1, result2
      end

      it "does not saves cache for #to_h" do
        context[:foo] = :bar
        jat_class.new("OBJECT", context).to_str

        assert_equal ["OBJECT.bar.to_str"], hash_storage.keys
      end
    end
  end
end
