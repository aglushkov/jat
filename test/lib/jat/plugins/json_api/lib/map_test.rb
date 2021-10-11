# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApi::Map" do
  before { Jat::Plugins.find_plugin(:json_api) }

  let(:described_class) { a::Map }
  let(:base_class) { Class.new(Jat) { plugin :json_api } }

  let(:a) do
    ser = Class.new(base_class)
    ser.type :a

    ser.attribute :a1
    ser.attribute :a2
    ser.attribute :a3, exposed: false

    ser.relationship :b, serializer: b, exposed: true
    ser.relationship :c, serializer: c
    ser.relationship :d, serializer: d
    ser
  end

  let(:b) do
    ser = Class.new(base_class)
    ser.type :b
    ser.attribute :b1
    ser.attribute :b2
    ser.attribute :b3, exposed: false

    ser.relationship :c, serializer: c
    ser.relationship :d, serializer: d
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

  describe "with default :exposed option" do
    it "returns exposed by default attributes" do
      result = described_class.call(exposed: :default)
      expected_result = {
        a: {serializer: a, attributes: %i[a1 a2], relationships: %i[b]},
        b: {serializer: b, attributes: %i[b1 b2], relationships: %i[]}
      }

      assert_equal expected_result, result
    end

    it "returns exposed by default attributes when no :exposed param provided" do
      result = described_class.call({})
      expected_result = {
        a: {serializer: a, attributes: %i[a1 a2], relationships: %i[b]},
        b: {serializer: b, attributes: %i[b1 b2], relationships: %i[]}
      }

      assert_equal expected_result, result
    end

    it "returns additionally included fields specified in :includes option" do
      includes = "c,b.d"
      result = described_class.call(include: includes)
      expected_result = {
        a: {serializer: a, attributes: %i[a1 a2], relationships: %i[b c]},
        b: {serializer: b, attributes: %i[b1 b2], relationships: %i[d]},
        c: {serializer: c, attributes: %i[c1 c2], relationships: %i[]},
        d: {serializer: d, attributes: %i[d1 d2], relationships: %i[]}
      }

      assert_equal expected_result, result
    end

    it "returns fields specified in :fields option (only specified fields for specified type)" do
      fields = {b: "b1,d"}
      result = described_class.call(fields: fields)
      expected_result = {
        a: {serializer: a, attributes: %i[a1 a2], relationships: %i[b]},
        b: {serializer: b, attributes: %i[b1], relationships: %i[d]},
        d: {serializer: d, attributes: %i[d1 d2], relationships: %i[]}
      }

      assert_equal expected_result, result
    end

    it "returns fields specified in :includes and :fields options" do
      includes = "c"
      fields = {c: "c1"}
      result = described_class.call(include: includes, fields: fields)
      expected_result = {
        a: {serializer: a, attributes: %i[a1 a2], relationships: %i[b c]},
        b: {serializer: b, attributes: %i[b1 b2], relationships: %i[]},
        c: {serializer: c, attributes: %i[c1], relationships: %i[]}
      }

      assert_equal expected_result, result
    end
  end

  describe "with exposed: :none option" do
    it "returns no attributes" do
      result = described_class.call(exposed: :none)
      expected_result = {
        a: {serializer: a, attributes: %i[], relationships: %i[]}
      }

      assert_equal expected_result, result
    end

    it "returns additionally included fields specified in :includes option" do
      includes = "b.c"
      result = described_class.call(exposed: :none, include: includes)
      expected_result = {
        a: {serializer: a, attributes: %i[], relationships: %i[b]},
        b: {serializer: b, attributes: %i[], relationships: %i[c]},
        c: {serializer: c, attributes: %i[], relationships: %i[]}
      }

      assert_equal expected_result, result
    end

    it "returns fields specified in :fields option (only specified fields for specified type)" do
      fields = {a: "a1,b", b: "b1,d"}
      result = described_class.call(exposed: :none, fields: fields)
      expected_result = {
        a: {serializer: a, attributes: %i[a1], relationships: %i[b]},
        b: {serializer: b, attributes: %i[b1], relationships: %i[d]},
        d: {serializer: d, attributes: %i[], relationships: %i[]}
      }

      assert_equal expected_result, result
    end

    it "returns fields specified in :includes and :fields options" do
      includes = "c"
      fields = {c: "c1"}
      result = described_class.call(exposed: :none, include: includes, fields: fields)
      expected_result = {
        a: {serializer: a, attributes: %i[], relationships: %i[c]},
        c: {serializer: c, attributes: %i[c1], relationships: %i[]}
      }

      assert_equal expected_result, result
    end
  end

  describe "with exposed: :all option" do
    it "returns all attributes" do
      result = described_class.call(exposed: :all)
      expected_result = {
        a: {serializer: a, attributes: %i[a1 a2 a3], relationships: %i[b c d]},
        b: {serializer: b, attributes: %i[b1 b2 b3], relationships: %i[c d]},
        c: {serializer: c, attributes: %i[c1 c2 c3], relationships: %i[]},
        d: {serializer: d, attributes: %i[d1 d2 d3], relationships: %i[]}
      }

      assert_equal expected_result, result
    end

    it "returns only specified fields for specified fields types" do
      fields = {b: "b1", c: "c2"}
      result = described_class.call(exposed: :all, fields: fields)
      expected_result = {
        a: {serializer: a, attributes: %i[a1 a2 a3], relationships: %i[b c d]},
        b: {serializer: b, attributes: %i[b1], relationships: %i[]},
        c: {serializer: c, attributes: %i[c2], relationships: %i[]},
        d: {serializer: d, attributes: %i[d1 d2 d3], relationships: %i[]}
      }

      assert_equal expected_result, result
    end
  end
end
