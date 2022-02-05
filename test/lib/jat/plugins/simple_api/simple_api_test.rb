# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::SimpleApi" do
  before { @plugin = Jat::Plugins.find_plugin(:simple_api) }

  let(:serializer_class) do
    new_class = Class.new(Jat)
    new_class.plugin(plugin)
    new_class.root :data
    new_class.attribute :id, key: :itself
    new_class
  end

  let(:plugin) { @plugin }

  describe ".before_load" do
    it "raises error if response plugin was already loaded" do
      serializer_class = Class.new(Jat)
      serializer_class.config[:response_plugin_loaded] = :foobar

      err = assert_raises(Jat::Error) { serializer_class.plugin(:simple_api) }
      assert_equal("Response plugin `foobar` was already loaded before", err.message)
    end
  end

  describe ".after_load" do
    it "adds default `:meta` meta_key config option" do
      serializer_class = Class.new(Jat)
      assert_nil serializer_class.config[:meta_key]

      plugin.load(serializer_class)
      plugin.after_load(serializer_class)
      assert_equal :meta, serializer_class.config[:meta_key]
    end

    it "adds config variable with name of response plugin that was loaded" do
      serializer_class = Class.new(Jat)
      serializer_class.plugin(:simple_api)

      assert_equal(:simple_api, serializer_class.config[:response_plugin_loaded])
    end
  end

  describe "InstanceMethods" do
    let(:jat) { serializer_class.new({}) }

    describe "#to_h" do
      it "returns response in a simple-api format" do
        expected_result = {data: {id: "JAT"}}
        assert_equal expected_result, jat.to_h("JAT")
      end
    end

    describe "#map" do
      it "returns map for provided context" do
        serializer_class::Map.expects(:call).with("CONTEXT").returns "MAP"
        assert_equal "MAP", serializer_class.new("CONTEXT").map
      end
    end

    describe "#map_full" do
      it "returns memorized map with all fields exposed" do
        serializer_class::Map.expects(:call).with(exposed: :all).returns "MAP"
        assert_equal "MAP", serializer_class.map_full
        assert_same serializer_class.map_full, serializer_class.map_full
      end
    end

    describe "#map_exposed" do
      it "returns memorized map with exposed by default fields" do
        serializer_class::Map.expects(:call).with(exposed: :default).returns "MAP"
        assert_equal "MAP", serializer_class.map_exposed
        assert_same serializer_class.map_exposed, serializer_class.map_exposed
      end
    end
  end

  describe "ClassMethods" do
    describe ".root" do
      it "sets root config values" do
        serializer_class.root :data

        assert_equal :data, serializer_class.config[:root_one]
        assert_equal :data, serializer_class.config[:root_many]
      end

      it "sets root config values separately for one or many objects" do
        serializer_class.root one: "user", many: "users"

        assert_equal :user, serializer_class.config[:root_one]
        assert_equal :users, serializer_class.config[:root_many]
      end

      it "removes root values when `false` or `nil` provided" do
        serializer_class.root :data
        serializer_class.root false

        assert_nil serializer_class.config[:root_one]
        assert_nil serializer_class.config[:root_many]

        serializer_class.root :data
        serializer_class.root nil

        assert_nil serializer_class.config[:root_one]
        assert_nil serializer_class.config[:root_many]
      end

      it "removes root values when `false` or nil provided in hash" do
        serializer_class.root :data
        serializer_class.root one: nil, many: nil
        assert_nil serializer_class.config[:root_one]
        assert_nil serializer_class.config[:root_many]

        serializer_class.root :data
        serializer_class.root one: false, many: false
        assert_nil serializer_class.config[:root_one]
        assert_nil serializer_class.config[:root_many]
      end

      it "symbolizes root" do
        serializer_class.root "data"
        assert_equal :data, serializer_class.config[:root_one]
        assert_equal :data, serializer_class.config[:root_many]

        serializer_class.root one: "user", many: "users"
        assert_equal :user, serializer_class.config[:root_one]
        assert_equal :users, serializer_class.config[:root_many]
      end
    end

    describe ".meta_key" do
      it "returns default meta_key" do
        assert_equal :meta, serializer_class.config[:meta_key]
      end

      it "changes meta key" do
        serializer_class.meta_key :metadata
        assert_equal :metadata, serializer_class.config[:meta_key]
      end

      it "symbolizes meta key" do
        serializer_class.meta_key "metadata"
        assert_equal :metadata, serializer_class.config[:meta_key]
      end
    end

    describe ".inherited" do
      it "inherits root" do
        serializer_class.root(:foo)
        child = Class.new(serializer_class)
        assert_equal :foo, child.config[:root_one]
        assert_equal :foo, child.config[:root_many]
      end

      it "inherits meta" do
        serializer_class.meta(:foo) { "bar" }
        child = Class.new(serializer_class)

        assert_equal "bar", child.added_meta[:foo].value(nil, nil)
      end

      it "does not change parents meta when children meta changed" do
        serializer_class.meta(:foo) { "foo" }
        child = Class.new(serializer_class)
        child.meta(:foo) { "bazz" }

        assert_equal("foo", serializer_class.added_meta[:foo].value(nil, nil))
        assert_equal("bazz", child.added_meta[:foo].value(nil, nil))
      end
    end
  end
end
