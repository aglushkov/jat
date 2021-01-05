# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApi::TraversalMap" do
  let(:jat_class) do
    new_class = Class.new(Jat)
    new_class.attribute :foo, exposed: true
    new_class.attribute :bar, exposed: false
    new_class
  end

  let(:jat) do
    jat_class.new("JAT", params: {fields: {jat: "bar"}})
  end

  before do
    jat_class.plugin :json_api
    jat_class.type :jat
  end

  describe "#jat" do
    it "returns initialization value" do
      map = Jat::Plugins::JsonApi::TraversalMap.new(jat)
      assert_same jat, map.jat
    end
  end

  describe "#exposed" do
    it "returns memorized exposed map" do
      map = Jat::Plugins::JsonApi::TraversalMap.new(jat)
      expected_map_hash = Jat::Plugins::JsonApi::ConstructTraversalMap.new(jat_class, :exposed).to_h

      assert_equal expected_map_hash, map.exposed
      assert_same map.exposed, map.exposed
    end
  end

  describe "#full" do
    it "returns memorized full map" do
      map = Jat::Plugins::JsonApi::TraversalMap.new(jat)
      expected_map_hash = Jat::Plugins::JsonApi::ConstructTraversalMap.new(jat_class, :all).to_h

      assert_equal expected_map_hash, map.full
      assert_same map.full, map.full
    end
  end

  describe "#current" do
    it "returns memorized current map" do
      map = Jat::Plugins::JsonApi::TraversalMap.new(jat)
      expected_map_hash = Jat::Plugins::JsonApi::Map.call(jat)

      assert_equal expected_map_hash, map.current
      assert_same map.current, map.current
    end
  end
end
