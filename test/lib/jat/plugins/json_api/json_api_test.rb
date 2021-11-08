# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApi" do
  let(:jat_class) do
    new_class = Class.new(Jat)
    new_class.plugin(plugin)
    new_class.type :jat
    new_class.id key: :itself
    new_class
  end

  let(:plugin) { Jat::Plugins.find_plugin(:json_api) }

  describe ".before_load" do
    it "checks some response plugin was already loaded" do
      jat_class = Class.new(Jat)
      jat_class.config[:response_plugin_loaded] = :simple_api
      error = assert_raises(Jat::Error) { jat_class.plugin(:json_api) }
      assert_equal "Response plugin `simple_api` was already loaded before", error.message
    end
  end

  describe ".after_load" do
    it "adds config variable with name of response plugin that was loaded" do
      jat_class = Class.new(Jat)
      jat_class.plugin(:json_api)

      assert_equal(:json_api, jat_class.config[:response_plugin_loaded])
    end
  end

  describe "InstanceMethods" do
    let(:jat) do
      jat_class.new
    end

    describe "#to_h" do
      it "returns response in json-api format" do
        expected_result = {data: {type: :jat, id: "JAT"}}
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
    describe ".id" do
      it "adds new `:id`" do
        jat_class.id(key: :uuid)
        assert_equal jat_class.get_id.params, {name: :id, opts: {key: :uuid}, block: nil}
      end
    end

    describe ".inherited" do
      it "inherits type" do
        child = Class.new(jat_class)
        assert_equal :jat, child.get_type
      end

      it "inherits `jsonapi` data" do
        jat_class.jsonapi(:version) { "1.0" }

        child = Class.new(jat_class)
        assert_equal("1.0", child.jsonapi_data[:version].value(nil, nil))
      end

      it "inherits `object_links`, `relationship_links`, `document_links`" do
        jat_class.object_link(:self) { "/articles/1" }
        jat_class.relationship_link(:related) { "/articles/2" }
        jat_class.document_link(:last) { "/articles/3" }
        child = Class.new(jat_class)

        assert_equal("/articles/1", child.object_links[:self].value(nil, nil))
        assert_equal("/articles/2", child.relationship_links[:related].value(nil, nil))
        assert_equal("/articles/3", child.document_links[:last].value(nil, nil))
      end

      it "does not change parents links when children links are changed" do
        jat_class.object_link(:self) { "/articles/1" }
        jat_class.relationship_link(:related) { "/articles/2" }
        jat_class.document_link(:last) { "/articles/3" }

        child = Class.new(jat_class)
        child.object_links.delete(:self)
        child.relationship_links.delete(:related)
        child.document_links.delete(:last)

        assert_equal("/articles/1", jat_class.object_links[:self].value(nil, nil))
        assert_equal("/articles/2", jat_class.relationship_links[:related].value(nil, nil))
        assert_equal("/articles/3", jat_class.document_links[:last].value(nil, nil))
      end

      it "inherits `object_meta`, `relationship_meta`, `document_meta`" do
        jat_class.object_meta(:self) { "foo/1" }
        jat_class.relationship_meta(:related) { "foo/2" }
        jat_class.document_meta(:last) { "foo/3" }
        child = Class.new(jat_class)

        assert_equal("foo/1", child.added_object_meta[:self].value(nil, nil))
        assert_equal("foo/2", child.added_relationship_meta[:related].value(nil, nil))
        assert_equal("foo/3", child.added_document_meta[:last].value(nil, nil))
      end

      it "does not change parents meta when children meta changed" do
        jat_class.object_meta(:self) { "foo/1" }
        jat_class.relationship_meta(:related) { "foo/2" }
        jat_class.document_meta(:last) { "foo/3" }

        child = Class.new(jat_class)
        child.added_object_meta.delete(:self)
        child.added_relationship_meta.delete(:related)
        child.added_document_meta.delete(:last)

        assert_equal("foo/1", jat_class.added_object_meta[:self].value(nil, nil))
        assert_equal("foo/2", jat_class.added_relationship_meta[:related].value(nil, nil))
        assert_equal("foo/3", jat_class.added_document_meta[:last].value(nil, nil))
      end
    end

    describe ".type, .get_type" do
      it "does not allows to ask for type before type is defined" do
        new_class = Class.new(Jat) { plugin(:json_api) }

        error = assert_raises(Jat::Error) { new_class.get_type }
        assert_equal "#{new_class} has no defined type", error.message
      end

      it "saves and returns current type" do
        assert_equal :jat, jat_class.get_type
      end

      it "symbolizes type" do
        jat_class.type "users"
        assert_equal :users, jat_class.get_type
      end
    end
  end
end
