# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApi::ConstructTraversalMap" do
  before { Jat::Plugins.load_plugin(:json_api) }

  let(:described_class) { Jat::Plugins::JsonApi::ConstructTraversalMap }
  let(:base_class) { Class.new(Jat) { plugin :json_api } }

  let(:a) do
    ser = Class.new(base_class)
    ser.type :a

    ser.attribute :a1
    ser.attribute :a2
    ser.attribute :a3, exposed: false

    ser.relationship :b, serializer: b
    ser.relationship :c, serializer: c
    ser.relationship :d, serializer: d, exposed: true
    ser
  end

  let(:b) do
    ser = Class.new(base_class)
    ser.type :b
    ser.attribute :b1
    ser.attribute :b2
    ser.attribute :b3, exposed: false
    ser
  end

  let(:c) do
    ser = Class.new(base_class)
    ser.type :c
    ser.attribute :c1
    ser.attribute :c2
    ser.attribute :c3, exposed: false
    ser
  end

  let(:d) do
    ser = Class.new(base_class)
    ser.type :d
    ser.attribute :d1
    ser.attribute :d2
    ser.attribute :d3, exposed: false
    ser
  end

  it "returns all attributes" do
    result = described_class.new(a, :all).to_h
    expected_result = {
      a: {serializer: a, attributes: %i[a1 a2 a3], relationships: %i[b c d]},
      b: {serializer: b, attributes: %i[b1 b2 b3], relationships: []},
      c: {serializer: c, attributes: %i[c1 c2 c3], relationships: []},
      d: {serializer: d, attributes: %i[d1 d2 d3], relationships: []}
    }

    assert_equal expected_result, result
  end

  it "returns exposed attributes" do
    result = described_class.new(a, :exposed).to_h
    expected_result = {
      a: {serializer: a, attributes: %i[a1 a2], relationships: %i[d]},
      d: {serializer: d, attributes: %i[d1 d2], relationships: []}
    }

    assert_equal expected_result, result
  end

  it "returns only manually exposed per-type attributes or exposed by default when no manual type provided" do
    exposed = {
      a: %i[a2 a3 c d],
      c: %i[c2 c3],
      d: %i[d2 d3]
    }
    result = described_class.new(a, :manual, manually_exposed: exposed).to_h
    expected_result = {
      a: {serializer: a, attributes: %i[a2 a3], relationships: %i[c d]},
      c: {serializer: c, attributes: %i[c2 c3], relationships: []},
      d: {serializer: d, attributes: %i[d2 d3], relationships: []}
    }

    assert_equal expected_result, result
  end

  it "returns manually exposed per-type attributes or exposed by default when no manual type provided" do
    exposed = {
      a: %i[a2 a3 b c],
      c: %i[c2 c3]
    }
    result = described_class.new(a, :manual, manually_exposed: exposed).to_h
    expected_result = {
      a: {serializer: a, attributes: %i[a2 a3], relationships: %i[b c]},
      b: {serializer: b, attributes: %i[b1 b2], relationships: []},
      c: {serializer: c, attributes: %i[c2 c3], relationships: []}
    }

    assert_equal expected_result, result
  end

  it "returns combined auto-exposed and manualy exposed attributes" do
    exposed = {
      a: %i[c],
      c: %i[c3]
    }
    result = described_class.new(a, :exposed, manually_exposed: exposed).to_h
    expected_result = {
      a: {serializer: a, attributes: %i[a1 a2], relationships: %i[c d]},
      c: {serializer: c, attributes: %i[c1 c2 c3], relationships: []},
      d: {serializer: d, attributes: %i[d1 d2], relationships: []}
    }

    assert_equal expected_result, result
  end
end
