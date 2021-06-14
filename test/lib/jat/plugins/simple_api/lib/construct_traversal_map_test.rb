# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApi::SimpleApi::ConstructTraversalMap" do
  before { Jat::Plugins.load_plugin(:simple_api) }

  let(:described_class) { Jat::Plugins::SimpleApi::ConstructTraversalMap }
  let(:base_class) { Class.new(Jat) { plugin :simple_api } }

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

  it "returns all attributes" do
    result = described_class.new(a, :all).to_h
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

  it "returns exposed attributes" do
    result = described_class.new(a, :exposed).to_h
    expected_result = {
      a1: {},
      a2: {},
      d: {d1: {}, d2: {}}
    }

    assert_equal expected_result, result
  end

  it "returns only manually exposed attributes when `none` type provided" do
    manually_exposed = {
      a2: {},
      a3: {},
      c: {c2: {}, c3: {}},
      d: {d2: {}, d3: {}}
    }
    result = described_class.new(a, :none, manually_exposed: manually_exposed).to_h

    assert_equal manually_exposed, result
  end

  it "returns combined auto-exposed and manualy exposed attributes when `default` type provided" do
    manually_exposed = {
      b: {b3: {}}, c: {}
    }
    result = described_class.new(a, :default, manually_exposed: manually_exposed).to_h
    expected_result = {
      a1: {},
      a2: {},
      b: {b1: {}, b2: {}, b3: {}},
      c: {c1: {}, c2: {}},
      d: {d1: {}, d2: {}}
    }

    assert_equal expected_result, result
  end
end
