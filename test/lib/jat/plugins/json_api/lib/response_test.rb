# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApi::Response" do
  let(:base_class) { Class.new(Jat) { plugin :json_api } }

  it "returns empty hash when nothing to serialize" do
    empty_serializer = Class.new(base_class) { type :foo }

    assert_equal({}, empty_serializer.to_h(nil))
  end

  it "returns correct structure with meta" do
    empty_serializer = Class.new(base_class) { type :foo }

    assert_equal({meta: {any: :thing}}, empty_serializer.to_h(nil, meta: {any: :thing}))
  end

  it "returns correct structure with data" do
    str_serializer = Class.new(base_class) do
      type "str"
      attribute(:id) { |_| "STRING" }
    end

    assert_equal({data: {type: :str, id: "STRING"}}, str_serializer.to_h("STRING"))
  end

  it "returns correct structure with array data" do
    str_serializer = Class.new(base_class) do
      type "str"
      attribute(:id) { |obj| obj }
    end

    assert_equal(
      {data: [{type: :str, id: "1"}, {type: :str, id: "2"}]},
      str_serializer.to_h(%w[1 2], many: true)
    )
  end

  it "returns correct structure with data and meta" do
    str_serializer = Class.new(base_class) do
      type "str"
      attribute(:id) { |obj| obj }
    end

    assert_equal(
      {data: {type: :str, id: "STRING"}, meta: {any: :thing}},
      str_serializer.to_h("STRING", meta: {any: :thing})
    )
  end

  it "returns correct structure with data with attributes" do
    str_serializer = Class.new(base_class) do
      type "str"
      attribute(:id) { |obj| obj[0] }
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
      attribute(:id) { |obj| obj }
    end

    str_serializer = Class.new(base_class) do
      type "str"
      attribute(:id) { |obj| obj[0] }
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
      attribute(:id) { |obj| obj }
    end

    str_serializer = Class.new(base_class) do
      type "str"
      attribute(:id) { |obj| obj[0] }
      relationship :length, serializer: int_serializer # relationships are not exposed by default
    end

    assert_equal({data: {type: :str, id: "S"}}, str_serializer.to_h("STRING"))
  end

  it "returns correct structure with empty has-one relationship" do
    str_serializer = Class.new(base_class) do
      type "str"
      attribute(:id) { |obj| obj[0] }
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
      attribute(:id) { |obj| obj }
      attribute(:next) { |obj| obj + 1 }
    end

    str_serializer = Class.new(base_class) do
      type "str"
      attribute(:id) { |obj| obj[0] }
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
      attribute(:id) { |_obj| "id" }
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
      attribute(:id) { |obj| obj }
    end

    str_serializer = Class.new(base_class) do
      type "str"
      attribute(:id) { |obj| obj[0] }
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
      attribute(:id) { |obj| obj }
      attribute :next
    end

    str_serializer = Class.new(base_class) do
      type "str"
      attribute(:id) { |obj| obj[0] }
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
      attribute(:id) { |obj| obj }
    end

    str_serializer = Class.new(base_class) do
      type "str"
      attribute(:id) { |obj| obj[0] }
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
      str_serializer.to_h("ab", params: {include: "chars"})
    )
  end

  it "accepts sparse_fieldset" do
    chr_serializer = Class.new(base_class) do
      type "chr"
      attribute(:id) { |obj| obj }
    end

    str_serializer = Class.new(base_class) do
      type "str"
      attribute(:id) { |obj| obj[0] }
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
      str_serializer.to_h("ab", params: {fields: {str: "chars"}})
    )
  end

  describe "meta" do
    it "adds static and dynamic meta defined in serializer config" do
      serializer = Class.new(base_class) do
        type :foo
        attribute(:id) { |obj| obj }

        config[:meta] = {
          version: "1.2.3",
          uid: ->(obj, context) { [obj, context[:time]] }
        }
      end

      assert_equal(
        {
          data: {type: :foo, id: "bar"},
          meta: {
            version: "1.2.3",
            uid: ["bar", "12:00"]
          }
        },
        serializer.to_h("bar", time: "12:00")
      )
    end

    it "does not overwrites manually added meta" do
      serializer = Class.new(base_class) do
        type :foo
        attribute(:id) { |obj| obj }
        config[:meta] = {version: "1.2.3", foo: :bar}
      end

      assert_equal(
        {
          data: {type: :foo, id: "bar"},
          meta: {version: "1.2.4", foo: :bar}
        },
        serializer.to_h("bar", meta: {version: "1.2.4"})
      )
    end

    it "does not add meta with nil values" do
      serializer = Class.new(base_class) do
        type :foo
        attribute(:id, key: :itself)
        config[:meta] = {
          foo: nil,
          bar: proc {},
          bazz: proc { false },
          bazzz: false
        }
      end

      assert_equal(
        {data: {type: :foo, id: "bar"}, meta: {bazz: false, bazzz: false}},
        serializer.to_h("bar")
      )
    end
  end
end
