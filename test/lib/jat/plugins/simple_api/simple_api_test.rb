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

  describe ".after_apply" do
    it "loads _json_api_activerecord plugin if activerecord option provided" do
      jat_class = Class.new(Jat)
      jat_class.expects(:plugin).with(:_json_api_activerecord, activerecord: true)

      plugin.apply(jat_class)
      plugin.after_apply(jat_class, activerecord: true)
    end

    it "adds default `:meta` meta_key config option" do
      jat_class = Class.new(Jat)
      assert_nil jat_class.config[:meta_key]

      plugin.apply(jat_class)
      plugin.after_apply(jat_class, activerecord: true)
      assert_equal :meta, jat_class.config[:meta_key]
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
