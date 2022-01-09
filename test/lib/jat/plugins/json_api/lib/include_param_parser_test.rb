# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApi::Params::Include" do
  before { Jat::Plugins.find_plugin(:json_api) }

  let(:base_class) { Class.new(Jat) { plugin :json_api } }
  let(:a_serializer) { Class.new(base_class) }
  let(:b_serializer) { Class.new(base_class) }
  let(:c_serializer) { Class.new(base_class) }

  before do
    ser = a_serializer
    ser.type :a
    ser.attribute :a1
    ser.relationship :a2, serializer: b_serializer
    ser.relationship :a3, serializer: b_serializer
    ser.relationship :a4, serializer: b_serializer
    ser.relationship :a5, serializer: b_serializer
    ser.relationship :a6, serializer: b_serializer

    ser = b_serializer
    ser.type :b
    ser.attribute :b1
    ser.relationship :b2, serializer: c_serializer
    ser.relationship :b3, serializer: c_serializer
    ser.relationship :b4, serializer: c_serializer

    ser = c_serializer
    ser.type :c
    ser.attribute :c1
    ser.relationship :c2, serializer: a_serializer
    ser.relationship :c3, serializer: a_serializer
    ser.relationship :c4, serializer: a_serializer
  end

  let(:described_class) { a_serializer::IncludeParamParser }

  describe ".inspect" do
    it "returns self name" do
      assert_equal "#{a_serializer}::IncludeParamParser", described_class.inspect
    end
  end

  describe ".parse" do
    it "returns empty hash when param not provided" do
      result = described_class.parse(nil)
      assert_equal({}, result)
    end

    it "returns typed keys" do
      result = described_class.parse("a2.b2.c2,a2.b2.c3,a3.b2.c4.a5,a4")
      assert_equal({a: %i[a2 a3 a5 a4], b: %i[b2], c: %i[c2 c3 c4]}, result)
    end
  end
end
