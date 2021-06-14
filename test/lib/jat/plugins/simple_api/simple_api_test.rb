# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::SimpleApi" do
  before { @plugin = Jat::Plugins.load_plugin(:simple_api) }

  let(:jat_class) do
    new_class = Class.new(Jat)
    new_class.plugin(plugin)
    new_class.root :data
    new_class.attribute :id, key: :itself
    new_class
  end

  let(:plugin) { @plugin }

  describe ".after_load" do
    it "loads _json_api_activerecord plugin if activerecord option provided" do
      jat_class = Class.new(Jat)
      jat_class.expects(:plugin).with(:_json_api_activerecord, activerecord: true)

      Jat::Plugins.after_load(plugin, jat_class, activerecord: true)
    end
  end

  describe "InstanceMethods" do
    let(:jat) { jat_class.new("JAT", {}) }

    describe "#to_h" do
      it "returns response in a simple-api format" do
        expected_result = {data: {id: "JAT"}}
        assert_equal expected_result, jat.to_h
      end
    end

    describe "#traversal_map" do
      it "returns memorized traversal_map hash" do
        assert_equal jat.traversal_map.class, Hash
        assert_same jat.traversal_map, jat.traversal_map
      end
    end
  end

  describe "ClassMethods" do
    describe ".inherited" do
      it "inherits root" do
        child = Class.new(jat_class)
        assert_equal :data, child.root
      end
    end

    describe ".root" do
      it "saves and returns current root" do
        assert_equal :data, jat_class.root
      end

      it "symbolizes root" do
        jat_class.root "users"
        assert_equal :users, jat_class.root
      end
    end

    describe ".meta_key" do
      it "returns default meta_key" do
        assert_equal :meta, jat_class.meta_key
      end

      it "saves and returns meta key" do
        jat_class.meta_key :metadata
        assert_equal :metadata, jat_class.meta_key
        assert_same jat_class.meta_key, jat_class.meta_key
      end

      it "symbolizes meta key" do
        jat_class.meta_key "metadata"
        assert_equal :metadata, jat_class.meta_key
      end
    end
  end
end
