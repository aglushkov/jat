# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApi::Map" do
  subject { Jat::Plugins::JsonApi::Map.call(jat) }

  let(:jat_class) do
    Class.new(Jat) do
      plugin :json_api
      type :jat
    end
  end
  let(:jat) { jat_class.new(nil, params: {fields: param_fields, include: param_includes}) }

  let(:default_map) { {a: :a1, b: :b1, c: :c1} }
  let(:includes_map) { {b: :b2, c: :c2} }
  let(:fields_map) { {c: :c3} }

  before do
    jat.traversal_map.expects(:exposed).returns(default_map)
  end

  describe "when no params given" do
    let(:param_includes) { nil }
    let(:param_fields) { nil }

    it "returns map of exposed by default fields" do
      assert_equal default_map, subject
    end
  end

  describe "when fields given" do
    let(:param_includes) { nil }
    let(:param_fields) { "FIELDS" }

    before do
      constructor = Jat::Plugins::JsonApi::ConstructTraversalMap.allocate
      constructor.expects(:to_h).returns(fields_map)

      Jat::Plugins::JsonApi::Params::Fields
        .expects(:call)
        .with(jat, "FIELDS")
        .returns("PARSED_FIELDS")

      Jat::Plugins::JsonApi::ConstructTraversalMap
        .expects(:new)
        .with(jat_class, :manual, manually_exposed: "PARSED_FIELDS")
        .returns(constructor)
    end

    it "constructs map with default and provided fields" do
      assert_equal({a: :a1, b: :b1, c: :c3}, subject)
    end
  end

  describe "when includes given" do
    let(:param_includes) { "INCLUDES" }
    let(:param_fields) { nil }

    before do
      constructor = Jat::Plugins::JsonApi::ConstructTraversalMap.allocate
      constructor.expects(:to_h).returns(includes_map)

      Jat::Plugins::JsonApi::Params::Include
        .expects(:call)
        .with(jat, "INCLUDES")
        .returns("PARSED_INCLUDES")

      Jat::Plugins::JsonApi::ConstructTraversalMap
        .expects(:new)
        .with(jat_class, :exposed, manually_exposed: "PARSED_INCLUDES")
        .returns(constructor)
    end

    it "constructs map with default and included fields" do
      assert_equal({a: :a1, b: :b2, c: :c2}, subject)
    end
  end

  describe "when fields and includes given" do
    let(:param_fields) { "FIELDS" }
    let(:param_includes) { "INCLUDES" }

    before do
      constructor1 = Jat::Plugins::JsonApi::ConstructTraversalMap.allocate
      constructor1.expects(:to_h).returns(fields_map)

      Jat::Plugins::JsonApi::Params::Fields
        .expects(:call)
        .with(jat, "FIELDS")
        .returns("PARSED_FIELDS")

      Jat::Plugins::JsonApi::ConstructTraversalMap
        .expects(:new)
        .with(jat_class, :manual, manually_exposed: "PARSED_FIELDS")
        .returns(constructor1)

      constructor2 = Jat::Plugins::JsonApi::ConstructTraversalMap.allocate
      constructor2.expects(:to_h).returns(includes_map)

      Jat::Plugins::JsonApi::Params::Include
        .expects(:call)
        .with(jat, "INCLUDES")
        .returns("PARSED_INCLUDES")

      Jat::Plugins::JsonApi::ConstructTraversalMap
        .expects(:new)
        .with(jat_class, :exposed, manually_exposed: "PARSED_INCLUDES")
        .returns(constructor2)
    end

    it "constructs map with using everything: defaults, includes, fields" do
      assert_equal({a: :a1, b: :b2, c: :c3}, subject)
    end
  end
end
