# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApi::Params::Include" do
  before { Jat::Plugins.find_plugin(:json_api) }

  let(:base_class) { Class.new(Jat) { plugin :json_api } }
  let(:a_serializer) { Class.new(base_class) }
  let(:b_serializer) { Class.new(base_class) }

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
    ser.relationship :b2, serializer: a_serializer
    ser.relationship :b3, serializer: a_serializer
    ser.relationship :b4, serializer: a_serializer
  end

  let(:described_class) { a_serializer::IncludeParamParser }

  it "returns empty hash when param not provided" do
    result = described_class.parse(nil)
    assert_equal({}, result)
  end

  it "returns typed keys" do
    result = described_class.parse("a2.b2,a2.b3,a3.b2.a5,a4")
    assert_equal({a: %i[a2 a3 a5 a4], b: %i[b2 b3]}, result)
  end
end
