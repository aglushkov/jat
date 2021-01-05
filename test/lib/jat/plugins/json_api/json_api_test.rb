# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApi" do
  let(:jat_class) do
    new_class = Class.new(Jat)
    new_class.plugin(:json_api)
    new_class.type :jat
    new_class.attribute :id, key: :itself
    new_class
  end

  describe ".after_load" do
    it "loads _json_api_activerecord plugin if activerecord option provided" do
      json_api_plugin = Jat::Plugins.load_plugin(:json_api)

      jat_class.expects(:plugin).with(:_json_api_activerecord, {})

      json_api_plugin.after_load(jat_class, activerecord: true)
    end
  end

  describe "InstanceMethods" do
    let(:jat) do
      jat_class.new("JAT", {})
    end

    describe "#to_h" do
      it "returns response in json-api format" do
        expected_result = {data: {type: :jat, id: "JAT"}}
        assert_equal expected_result, jat.to_h
      end
    end

    describe "#traversal_map" do
      it "returns memorized traversal_map object" do
        assert_equal jat.traversal_map.class, Jat::Plugins::JsonApi::TraversalMap
        assert_same jat.traversal_map, jat.traversal_map
      end
    end
  end

  describe "ClassMethods" do
    describe ".relationship" do
      it "adds new attribute with required serializer" do
        jat_class.relationship(:foo, serializer: jat_class, exposed: true) { "block" }

        atribute = jat_class.attributes[:foo]
        assert_equal jat_class, atribute.serializer
        assert_equal true, atribute.exposed?
        assert_equal "block", jat_class::Presenter.new(nil, nil).foo
      end
    end

    describe ".inherited" do
      it "inherits type" do
        child = Class.new(jat_class)
        assert_equal :jat, child.type
      end
    end

    describe ".type" do
      it "does not allows to ask for type before type is defined" do
        new_class = Class.new(Jat) { plugin(:json_api) }

        error = assert_raises(Jat::Error) { new_class.type }
        assert_equal "#{new_class} has no defined type", error.message
      end

      it "saves and returns current type" do
        assert_equal :jat, jat_class.type
      end

      it "symbolizes type" do
        jat_class.type "users"
        assert_equal :users, jat_class.type
      end
    end
  end
end
