# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApi::Response" do
  let(:base_class) { Class.new(Jat) { plugin :json_api } }

  it "returns empty hash when nothing to serialize" do
    empty_serializer = Class.new(base_class) { type :foo }

    assert_equal({}, empty_serializer.to_h(nil))
  end

  it "returns correct structure with data" do
    str_serializer = Class.new(base_class) do
      type "str"
      id { |_| "STRING" }
    end

    assert_equal({data: {type: :str, id: "STRING"}}, str_serializer.to_h("STRING"))
  end

  it "returns correct structure with array data" do
    str_serializer = Class.new(base_class) do
      type "str"
      id { |obj| obj }
    end

    assert_equal(
      {data: [{type: :str, id: "1"}, {type: :str, id: "2"}]},
      str_serializer.to_h(%w[1 2], many: true)
    )
  end

  it "returns correct structure with data with attributes" do
    str_serializer = Class.new(base_class) do
      type "str"
      id { |obj| obj[0] }
      attribute :length
    end

    assert_equal(
      {data: {type: :str, id: "S", attributes: {length: 6}}},
      str_serializer.to_h("STRING")
    )
  end

  it "returns correct structure with has-one relationship" do
    int_serializer = Class.new(base_class) do
      type "int"
      id { |obj| obj }
    end

    str_serializer = Class.new(base_class) do
      type "str"
      id { |obj| obj[0] }
      relationship :length, serializer: int_serializer, exposed: true
    end

    assert_equal(
      {
        data: {
          type: :str, id: "S",
          relationships: {
            length: {data: {type: :int, id: 6}}
          }
        },
        included: [
          {type: :int, id: 6}
        ]
      },
      str_serializer.to_h("STRING")
    )
  end

  it "does not return has-one relationship when not exposed" do
    int_serializer = Class.new(base_class) do
      type "int"
      id { |obj| obj }
    end

    str_serializer = Class.new(base_class) do
      type "str"
      id { |obj| obj[0] }
      relationship :length, serializer: int_serializer # relationships are not exposed by default
    end

    assert_equal({data: {type: :str, id: "S"}}, str_serializer.to_h("STRING"))
  end

  it "returns correct structure with empty has-one relationship" do
    str_serializer = Class.new(base_class) do
      type "str"
      id { |obj| obj[0] }
      relationship(:length, serializer: self, exposed: true) { |_obj| nil }
    end

    assert_equal(
      {
        data: {
          type: :str, id: "S",
          relationships: {length: {data: nil}}
        }
      },
      str_serializer.to_h("STRING")
    )
  end

  it "returns correct structure with has-one relationship with attributes" do
    int_serializer = Class.new(base_class) do
      type "int"
      id { |obj| obj }
      attribute(:next) { |obj| obj + 1 }
    end

    str_serializer = Class.new(base_class) do
      type "str"
      id { |obj| obj[0] }
      relationship :length, serializer: int_serializer, exposed: true
    end

    assert_equal(
      {
        data: {
          type: :str, id: "S",
          relationships: {
            length: {data: {type: :int, id: 6}}
          }
        },
        included: [
          {type: :int, id: 6, attributes: {next: 7}}
        ]
      },
      str_serializer.to_h("STRING")
    )
  end

  it "returns correct structure with empty has-many relationship" do
    chr_serializer = Class.new(base_class) do
      type "chr"
    end

    str_serializer = Class.new(base_class) do
      type "str"
      id { |_obj| "id" }
      relationship :chars, serializer: chr_serializer, many: true, exposed: true
    end

    assert_equal(
      {
        data: {
          type: :str, id: "id",
          relationships: {chars: {data: []}}
        }
      },
      str_serializer.to_h("")
    )
  end

  it "returns correct structure with has-many relationship" do
    chr_serializer = Class.new(base_class) do
      type "chr"
      id { |obj| obj }
    end

    str_serializer = Class.new(base_class) do
      type "str"
      id { |obj| obj[0] }
      relationship :chars, serializer: chr_serializer, many: true, exposed: true
    end

    assert_equal(
      {
        data: {
          type: :str, id: "a",
          relationships: {
            chars: {data: [{type: :chr, id: "a"}, {type: :chr, id: "b"}]}
          }
        },
        included: [
          {type: :chr, id: "a"}, {type: :chr, id: "b"}
        ]
      },
      str_serializer.to_h("ab")
    )
  end

  it "returns correct structure with has-many relationship with attributes" do
    chr_serializer = Class.new(base_class) do
      type "chr"
      id { |obj| obj }
      attribute :next
    end

    str_serializer = Class.new(base_class) do
      type "str"
      id { |obj| obj[0] }
      relationship :chars, serializer: chr_serializer, many: true, exposed: true
    end

    assert_equal(
      {
        data: {
          type: :str, id: "a",
          relationships: {
            chars: {data: [{type: :chr, id: "a"}, {type: :chr, id: "b"}]}
          }
        },
        included: [
          {type: :chr, id: "a", attributes: {next: "b"}},
          {type: :chr, id: "b", attributes: {next: "c"}}
        ]
      },
      str_serializer.to_h("ab")
    )
  end

  it "accepts includes param" do
    chr_serializer = Class.new(base_class) do
      type "chr"
      id { |obj| obj }
    end

    str_serializer = Class.new(base_class) do
      type "str"
      id { |obj| obj[0] }
      relationship :chars, serializer: chr_serializer, many: true, exposed: false
    end

    assert_equal(
      {
        data: {
          type: :str, id: "a",
          relationships: {
            chars: {data: [{type: :chr, id: "a"}, {type: :chr, id: "b"}]}
          }
        },
        included: [
          {type: :chr, id: "a"}, {type: :chr, id: "b"}
        ]
      },
      str_serializer.to_h("ab", include: "chars")
    )
  end

  it "accepts sparse_fieldset" do
    chr_serializer = Class.new(base_class) do
      type "chr"
      id { |obj| obj }
    end

    str_serializer = Class.new(base_class) do
      type "str"
      id { |obj| obj[0] }
      relationship :chars, serializer: chr_serializer, many: true, exposed: false
    end

    assert_equal(
      {
        data: {
          type: :str, id: "a",
          relationships: {
            chars: {data: [{type: :chr, id: "a"}, {type: :chr, id: "b"}]}
          }
        },
        included: [
          {type: :chr, id: "a"}, {type: :chr, id: "b"}
        ]
      },
      str_serializer.to_h("ab", fields: {str: "chars"})
    )
  end

  describe "json_api" do
    let(:serializer) do
      Class.new(base_class) do
        type :foo
        id { |obj| obj }
      end
    end

    it "adds `jsonapi` fields defined in serializer" do
      serializer.jsonapi(:version) { "1.2.3" }
      serializer.jsonapi(:uid) { |obj, context| [obj, context[:time]] }

      response = serializer.to_h("bar", time: "12:00")
      jsonapi = response.dig(:jsonapi)
      assert_equal({version: "1.2.3", uid: ["bar", "12:00"]}, jsonapi)
    end

    it "does not overwrite manually added data" do
      serializer.jsonapi(:version) { "1.2.3" }
      serializer.jsonapi(:foo) { :bar }

      response = serializer.to_h("bar", jsonapi: {version: "3.2.1"})
      jsonapi = response.dig(:jsonapi)
      assert_equal({version: "3.2.1", foo: :bar}, jsonapi)
    end

    it "does not add jsonapi attributes with nil values" do
      serializer.jsonapi(:foo) {}
      serializer.jsonapi(:bar) { false }

      response = serializer.to_h("bar")
      jsonapi = response.dig(:jsonapi)
      assert_equal({bar: false}, jsonapi)
    end
  end

  describe "document_meta" do
    let(:serializer) do
      Class.new(base_class) do
        type :foo
        id { |obj| obj }
      end
    end

    it "adds document meta defined in serializer" do
      serializer.document_meta(:version) { "1.2.3" }
      serializer.document_meta(:uid) { |obj, context| [obj, context[:time]] }

      response = serializer.to_h("bar", time: "12:00")
      meta = response.dig(:meta)
      assert_equal({version: "1.2.3", uid: ["bar", "12:00"]}, meta)
    end

    it "does not overwrite manually added meta" do
      serializer.document_meta(:version) { "1.2.3" }
      serializer.document_meta(:foo) { :bar }

      response = serializer.to_h("bar", meta: {version: "3.2.1"})
      meta = response.dig(:meta)
      assert_equal({version: "3.2.1", foo: :bar}, meta)
    end

    it "does not add meta with nil values" do
      serializer.document_meta(:foo) {}
      serializer.document_meta(:bar) { false }

      response = serializer.to_h("bar")
      meta = response.dig(:meta)
      assert_equal({bar: false}, meta)
    end
  end

  describe "resource meta" do
    let(:serializer) do
      Class.new(base_class) do
        type :foo
        id { |obj| obj }
      end
    end

    it "adds meta defined in serializer" do
      serializer.object_meta(:version) { "1.2.3" }
      serializer.object_meta(:uid) { |obj, context| [obj, context[:time]] }

      response = serializer.to_h("bar", time: "12:00")
      meta = response.dig(:data, :meta)
      assert_equal({version: "1.2.3", uid: ["bar", "12:00"]}, meta)
    end

    it "does not add meta with nil values" do
      serializer.object_meta(:foo) {}
      serializer.object_meta(:bar) { false }

      response = serializer.to_h("bar")
      meta = response.dig(:data, :meta)
      assert_equal({bar: false}, meta)
    end
  end

  describe "relationship meta" do
    let(:bar_serializer) do
      Class.new(base_class) do
        type :bar
        id { |obj| obj }
      end
    end

    let(:foo_serializer) do
      Class.new(base_class) do
        type :foo
        id { |obj| obj }
      end
    end

    it "adds relationship meta defined in serializer" do
      foo_serializer.relationship(:bar, serializer: -> { bar_serializer }, exposed: true) { "bar" }
      bar_serializer.relationship_meta(:version) { "1.2.3" }
      bar_serializer.relationship_meta(:uid) { |obj, context| [context[:parent_object], obj, context[:time]] }
      bar_serializer.relationship_meta(:null) {}

      response = foo_serializer.to_h("foo", time: "12:00")
      meta = response.dig(:data, :relationships, :bar, :meta)
      assert_equal({version: "1.2.3", uid: ["foo", "bar", "12:00"]}, meta)
    end
  end

  describe "document_link" do
    let(:serializer) do
      Class.new(base_class) do
        type :foo
        id { |obj| obj }
      end
    end

    it "adds document links defined in serializer" do
      serializer.document_link(:self) { "/self" }
      serializer.document_link(:related) { |obj| "/#{obj}/self" }

      response = serializer.to_h("bar")
      links = response.dig(:links)
      assert_equal({self: "/self", related: "/bar/self"}, links)
    end

    it "does not overwrite manually added links" do
      serializer.document_link(:self) { "/self" }
      serializer.document_link(:related) { |obj| "/#{obj}/self" }

      response = serializer.to_h("bar", links: {self: "/foo"})
      links = response.dig(:links)
      assert_equal({self: "/foo", related: "/bar/self"}, links)
    end

    it "does not add links with nil values" do
      serializer.document_link(:foo) {}
      serializer.document_link(:bar) { false }

      response = serializer.to_h("bar")
      links = response.dig(:links)
      assert_equal({bar: false}, links)
    end
  end

  describe "resource links" do
    let(:serializer) do
      Class.new(base_class) do
        type :foo
        id { |obj| obj }
      end
    end

    it "adds links defined in serializer" do
      serializer.object_link(:self) { "/self" }
      serializer.object_link(:related) { |obj| "/#{obj}/self" }

      response = serializer.to_h("bar", time: "12:00")
      links = response.dig(:data, :links)
      assert_equal({self: "/self", related: "/bar/self"}, links)
    end

    it "does not add links with nil values" do
      serializer.object_link(:foo) {}
      serializer.object_link(:bar) { false }

      response = serializer.to_h("bar")
      links = response.dig(:data, :links)
      assert_equal({bar: false}, links)
    end
  end

  describe "relationship links" do
    let(:bar_serializer) do
      Class.new(base_class) do
        type :bar
        id { |obj| obj }
      end
    end

    let(:foo_serializer) do
      Class.new(base_class) do
        type :foo
        id { |obj| obj }
      end
    end

    it "adds relationship link defined in serializer" do
      foo_serializer.relationship(:bar, serializer: -> { bar_serializer }, exposed: true) { "bar" }
      bar_serializer.relationship_link(:self) { "/self" }
      bar_serializer.relationship_link(:related) { |_obj, ctx| "/#{ctx[:parent_object]}/self" }
      bar_serializer.relationship_link(:null) {}

      response = foo_serializer.to_h("foo")
      links = response.dig(:data, :relationships, :bar, :links)
      assert_equal({self: "/self", related: "/foo/self"}, links)
    end
  end

  describe ".inspect" do
    it "returns self name" do
      assert_equal "#{base_class}::Response", base_class::Response.inspect
    end
  end
end
