# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::SimpleApi" do
  before { @plugin = Jat::Plugins.find_plugin(:simple_api) }

  let(:jat_class) do
    new_class = Class.new(Jat)
    new_class.plugin(plugin)
    new_class.root :data
    new_class.attribute :id, key: :itself
    new_class
  end

  let(:plugin) { @plugin }

  describe ".after_load" do
    it "adds default `:meta` meta_key config option" do
      jat_class = Class.new(Jat)
      assert_nil jat_class.config[:meta_key]

      plugin.load(jat_class)
      plugin.after_load(jat_class)
      assert_equal :meta, jat_class.config[:meta_key]
    end

    it "adds config variable with name of response plugin that was loaded" do
      jat_class = Class.new(Jat)
      jat_class.plugin(:simple_api)

      assert_equal(:simple_api, jat_class.config[:response_plugin_loaded])
    end
  end

  describe "InstanceMethods" do
    let(:jat) { jat_class.new({}) }

    describe "#to_h" do
      it "returns response in a simple-api format" do
        expected_result = {data: {id: "JAT"}}
        assert_equal expected_result, jat.to_h("JAT")
      end
    end

    describe "#map" do
      it "returns map for provided context" do
        jat_class::Map.expects(:call).with("CONTEXT").returns "MAP"
        assert_equal "MAP", jat_class.map("CONTEXT")
      end
    end

    describe "#map_full" do
      it "returns memorized map with all fields exposed" do
        jat_class::Map.expects(:call).with(exposed: :all).returns "MAP"
        assert_equal "MAP", jat_class.map_full
        assert_same jat_class.map_full, jat_class.map_full
      end
    end

    describe "#map_exposed" do
      it "returns memorized map with exposed by default fields" do
        jat_class::Map.expects(:call).with(exposed: :default).returns "MAP"
        assert_equal "MAP", jat_class.map_exposed
        assert_same jat_class.map_exposed, jat_class.map_exposed
      end
    end
  end

  describe "ClassMethods" do
    describe ".root" do
      it "sets root config values" do
        jat_class.root :data

        assert_equal :data, jat_class.config[:root_one]
        assert_equal :data, jat_class.config[:root_many]
      end

      it "sets root config values separately for one or many objects" do
        jat_class.root one: "user", many: "users"

        assert_equal :user, jat_class.config[:root_one]
        assert_equal :users, jat_class.config[:root_many]
      end

      it "removes root values when `false` or `nil` provided" do
        jat_class.root :data
        jat_class.root false

        assert_nil jat_class.config[:root_one]
        assert_nil jat_class.config[:root_many]

        jat_class.root :data
        jat_class.root nil

        assert_nil jat_class.config[:root_one]
        assert_nil jat_class.config[:root_many]
      end

      it "removes root values when `false` or nil provided in hash" do
        jat_class.root :data
        jat_class.root one: nil, many: nil
        assert_nil jat_class.config[:root_one]
        assert_nil jat_class.config[:root_many]

        jat_class.root :data
        jat_class.root one: false, many: false
        assert_nil jat_class.config[:root_one]
        assert_nil jat_class.config[:root_many]
      end

      it "symbolizes root" do
        jat_class.root "data"
        assert_equal :data, jat_class.config[:root_one]
        assert_equal :data, jat_class.config[:root_many]

        jat_class.root one: "user", many: "users"
        assert_equal :user, jat_class.config[:root_one]
        assert_equal :users, jat_class.config[:root_many]
      end
    end

    describe ".meta_key" do
      it "returns default meta_key" do
        assert_equal :meta, jat_class.config[:meta_key]
      end

      it "changes meta key" do
        jat_class.meta_key :metadata
        assert_equal :metadata, jat_class.config[:meta_key]
      end

      it "symbolizes meta key" do
        jat_class.meta_key "metadata"
        assert_equal :metadata, jat_class.config[:meta_key]
      end
    end
  end
end
