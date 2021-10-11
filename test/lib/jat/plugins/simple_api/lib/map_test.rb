# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::SimpleApi::Map" do
  before { Jat::Plugins.find_plugin(:simple_api) }

  let(:base_class) { Class.new(Jat) { plugin :simple_api } }
  let(:described_class) { a::Map }

  let(:a) do
    ser = Class.new(base_class)

    ser.attribute :a1
    ser.attribute :a2
    ser.attribute :a3, exposed: false

    ser.attribute :b, serializer: b
    ser.attribute :c, serializer: c
    ser.attribute :d, serializer: d, exposed: true
    ser
  end

  let(:b) do
    ser = Class.new(base_class)
    ser.attribute :b1
    ser.attribute :b2
    ser.attribute :b3, exposed: false
    ser
  end

  let(:c) do
    ser = Class.new(base_class)
    ser.attribute :c1
    ser.attribute :c2
    ser.attribute :c3, exposed: false
    ser
  end

  let(:d) do
    ser = Class.new(base_class)
    ser.attribute :d1
    ser.attribute :d2
    ser.attribute :d3, exposed: false
    ser
  end

  it "returns all attributes when {exposed: :all} provided " do
    result = described_class.call(exposed: :all)
    expected_result = {
      a1: {},
      a2: {},
      a3: {},
      b: {b1: {}, b2: {}, b3: {}},
      c: {c1: {}, c2: {}, c3: {}},
      d: {d1: {}, d2: {}, d3: {}}
    }

    assert_equal expected_result, result
  end

  it "returns exposed attributes when {exposed: :default} provided" do
    result = described_class.call(exposed: :default)
    expected_result = {
      a1: {},
      a2: {},
      d: {d1: {}, d2: {}}
    }

    assert_equal expected_result, result
  end

  it "returns exposed attributes when no :exposed param provided" do
    result = described_class.call({})
    expected_result = {
      a1: {},
      a2: {},
      d: {d1: {}, d2: {}}
    }

    assert_equal expected_result, result
  end

  it "returns no attributes when `{exposed: :none}` provided" do
    result = described_class.call(exposed: :none)
    assert_equal({}, result)
  end

  it "returns only manually exposed attributes when `{exposed: :none}` type provided" do
    fields = "a2,a3,c(c2,c3),d(d2,d3)"
    result = described_class.call(exposed: :none, fields: fields)

    expected_result = {
      a2: {},
      a3: {},
      c: {c2: {}, c3: {}},
      d: {d2: {}, d3: {}}
    }

    assert_equal expected_result, result
  end

  it "returns combined auto-exposed and manually exposed attributes when `default` type provided" do
    fields = "b(b3),c"
    result = described_class.call(exposed: :default, fields: fields)
    expected_result = {
      a1: {},
      a2: {},
      b: {b1: {}, b2: {}, b3: {}},
      c: {c1: {}, c2: {}},
      d: {d1: {}, d2: {}}
    }

    assert_equal expected_result, result
  end

  it "raises error with informative message about recursive serialization" do
    a.relationship :b, serializer: -> { b }, exposed: true
    b.relationship :a, serializer: -> { a }, exposed: true

    error = assert_raises(Jat::Error) { described_class.call({}) }
    assert_includes "Recursive serialization: b -> a -> b", error.message
  end

  it "raises error with informative message about recursive serialization through 3 serializers" do
    a.relationship :b, serializer: -> { b }, exposed: true
    b.relationship :c, serializer: -> { c }, exposed: true
    c.relationship :a, serializer: -> { a }, exposed: true

    error = assert_raises(Jat::Error) { described_class.call({}) }
    assert_equal "Recursive serialization: b -> c -> a -> b", error.message
  end
end
