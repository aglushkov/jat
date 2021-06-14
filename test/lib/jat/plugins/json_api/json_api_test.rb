# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApi" do
  let(:jat_class) do
    new_class = Class.new(Jat)
    new_class.plugin(plugin)
    new_class.type :jat
    new_class.attribute :id, key: :itself
    new_class
  end

  let(:plugin) { Jat::Plugins.load_plugin(:json_api) }

  describe ".after_load" do
    it "loads _json_api_activerecord plugin if activerecord option provided" do
      jat_class = Class.new(Jat)
      jat_class.expects(:plugin).with(:_json_api_activerecord, activerecord: true)

      Jat::Plugins.after_load(plugin, jat_class, activerecord: true)
    end

    it "registers Presenters constants" do
      jat_class = Class.new(Jat)
      Jat::Plugins.after_load(plugin, jat_class, activerecord: true)

      assert_equal jat_class::JsonapiPresenter.jat_class, jat_class
      assert_equal jat_class::LinksPresenter.jat_class, jat_class
      assert_equal jat_class::DocumentLinksPresenter.jat_class, jat_class
      assert_equal jat_class::RelationshipLinksPresenter.jat_class, jat_class
      assert_equal jat_class::MetaPresenter.jat_class, jat_class
      assert_equal jat_class::DocumentMetaPresenter.jat_class, jat_class
      assert_equal jat_class::RelationshipMetaPresenter.jat_class, jat_class
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

      it "inherits `jsonapi` data" do
        jat_class.jsonapi(:version) { "1.0" }

        child = Class.new(jat_class)
        assert_equal("1.0", child.jsonapi_data[:version].call)
      end

      it "inherits `object_links`, `relationship_links`, `document_links`" do
        jat_class.object_link(:self) { "/articles/1" }
        jat_class.relationship_link(:related) { "/articles/2" }
        jat_class.document_link(:last) { "/articles/3" }
        child = Class.new(jat_class)

        assert_equal("/articles/1", child.object_links[:self].call)
        assert_equal("/articles/2", child.relationship_links[:related].call)
        assert_equal("/articles/3", child.document_links[:last].call)
      end

      it "does not change parents links when children links are changed" do
        jat_class.object_link(:self) { "/articles/1" }
        jat_class.relationship_link(:related) { "/articles/2" }
        jat_class.document_link(:last) { "/articles/3" }

        child = Class.new(jat_class)
        child.object_links.delete(:self)
        child.relationship_links.delete(:related)
        child.document_links.delete(:last)

        assert_equal("/articles/1", jat_class.object_links[:self].call)
        assert_equal("/articles/2", jat_class.relationship_links[:related].call)
        assert_equal("/articles/3", jat_class.document_links[:last].call)
      end

      it "inherits `object_meta`, `relationship_meta`, `document_meta`" do
        jat_class.object_meta(:self) { "foo/1" }
        jat_class.relationship_meta(:related) { "foo/2" }
        jat_class.document_meta(:last) { "foo/3" }
        child = Class.new(jat_class)

        assert_equal("foo/1", child.added_object_meta[:self].call)
        assert_equal("foo/2", child.added_relationship_meta[:related].call)
        assert_equal("foo/3", child.added_document_meta[:last].call)
      end

      it "does not change parents meta when children meta changed" do
        jat_class.object_meta(:self) { "foo/1" }
        jat_class.relationship_meta(:related) { "foo/2" }
        jat_class.document_meta(:last) { "foo/3" }

        child = Class.new(jat_class)
        child.added_object_meta.delete(:self)
        child.added_relationship_meta.delete(:related)
        child.added_document_meta.delete(:last)

        assert_equal("foo/1", jat_class.added_object_meta[:self].call)
        assert_equal("foo/2", jat_class.added_relationship_meta[:related].call)
        assert_equal("foo/3", jat_class.added_document_meta[:last].call)
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
