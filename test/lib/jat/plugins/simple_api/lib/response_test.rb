# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::SimpleApi::Response" do
  let(:base_class) { Class.new(Jat) { plugin :simple_api } }

  it "returns empty hash when nothing to serialize" do
    empty_serializer = Class.new(base_class)

    assert_equal({}, empty_serializer.to_h(nil))
  end

  it "returns correct structure with data" do
    str_serializer = Class.new(base_class) do
      attribute(:id) { |obj| obj }
    end

    assert_equal({id: "STRING"}, str_serializer.to_h("STRING"))
  end

  it "returns correct structure when parameter `many` defined manually" do
    str_serializer = Class.new(base_class) do
      attribute(:id) { |obj| obj[:foo] }
    end

    # By default hash is interpreted as `many: true` as it is Enumerable
    obj = {foo: :bar}
    context = {many: false}

    assert_equal({id: :bar}, str_serializer.to_h(obj, context))
  end

  it "returns correct structure with array data" do
    str_serializer = Class.new(base_class) do
      attribute(:id) { |obj| obj }
    end

    assert_equal(
      [{id: "1"}, {id: "2"}],
      str_serializer.to_h(%w[1 2])
    )
  end

  it "returns correct structure with array data" do
    str_serializer = Class.new(base_class) do
      attribute(:id) { |obj| obj }
    end

    assert_equal(
      [{id: "1"}, {id: "2"}],
      str_serializer.to_h(%w[1 2])
    )
  end

  it "returns correct structure with one object with root key" do
    str_serializer = Class.new(base_class) do
      root(:digit)
      attribute(:id) { |obj| obj }
    end

    assert_equal({digit: {id: "1"}}, str_serializer.to_h("1"))
  end

  it "returns correct structure with list with root key" do
    str_serializer = Class.new(base_class) do
      root(:digits)
      attribute(:id) { |obj| obj }
    end

    assert_equal(
      {digits: [{id: "1"}, {id: "2"}]},
      str_serializer.to_h(%w[1 2])
    )
  end

  it "returns correct roots" do
    str_serializer = Class.new(base_class) do
      root(one: :digit, many: :digits)

      attribute(:id) { |obj| obj }
    end

    assert_equal({digit: {id: "1"}}, str_serializer.to_h("1"))
    assert_equal({digits: [{id: "1"}]}, str_serializer.to_h(["1"]))
  end

  it "returns correct structures when root is overwritten" do
    str_serializer = Class.new(base_class) do
      root(:root)
      attribute(:id) { |obj| obj }
    end

    assert_equal({foo: {id: "1"}}, str_serializer.to_h("1", root: :foo))
    assert_equal({foo: {id: "1"}}, str_serializer.to_h("1", root: "foo"))
    assert_equal({id: "1"}, str_serializer.to_h("1", root: nil))
  end

  it "returns correct structure with data multiple attributes" do
    str_serializer = Class.new(base_class) do
      attribute(:id) { |obj| obj }
      attribute :length
    end

    assert_equal({id: "1", length: 1}, str_serializer.to_h("1"))
  end

  it "returns correct structure with has-one relationship" do
    int_serializer = Class.new(base_class) do
      attribute(:id) { |obj| obj }
    end

    str_serializer = Class.new(base_class) do
      attribute(:id) { |obj| obj[0] }
      attribute :length, serializer: int_serializer, exposed: true
    end

    assert_equal({id: "S", length: {id: 6}}, str_serializer.to_h("STRING"))
  end

  it "returns correct structure when children serializer defined as lambda" do
    int_serializer = Class.new(base_class) do
      attribute(:id) { |obj| obj }
    end

    str_serializer = Class.new(base_class) do
      attribute(:id) { |obj| obj[0] }
      attribute :length, serializer: -> { int_serializer }, exposed: true
    end

    assert_equal({id: "S", length: {id: 6}}, str_serializer.to_h("STRING"))
  end

  it "does not return has-one relationship when not exposed" do
    int_serializer = Class.new(base_class) do
      attribute(:id) { |obj| obj }
    end

    str_serializer = Class.new(base_class) do
      attribute(:id) { |obj| obj[0] }
      attribute :length, serializer: int_serializer, exposed: false
    end

    assert_equal({id: "S"}, str_serializer.to_h("STRING"))
  end

  it "returns nil as empty has-one relationship" do
    int_serializer = Class.new(base_class)

    str_serializer = Class.new(base_class) do
      attribute(:id) { |obj| obj[0] }
      attribute(:length, serializer: int_serializer, exposed: true) { |_obj| nil }
    end

    assert_equal(
      {id: "S", length: nil},
      str_serializer.to_h("STRING")
    )
  end

  it "returns correct structure with has-one relationship with attributes" do
    int_serializer = Class.new(base_class) do
      attribute(:id) { |obj| obj }
      attribute(:next) { |obj| obj + 1 }
    end

    str_serializer = Class.new(base_class) do
      attribute(:id) { |obj| obj[0] }
      attribute :length, serializer: int_serializer, exposed: true
    end

    assert_equal(
      {id: "S", length: {id: 6, next: 7}},
      str_serializer.to_h("STRING")
    )
  end

  it "returns empty array as empty has-many relationship" do
    chr_serializer = Class.new(base_class)
    str_serializer = Class.new(base_class) do
      attribute(:id) { |_obj| "id" }
      attribute :chars, serializer: chr_serializer, many: true, exposed: true
    end

    assert_equal({id: "id", chars: []}, str_serializer.to_h(""))
  end

  it "returns correct structure with has-many relationship" do
    chr_serializer = Class.new(base_class) do
      attribute(:id) { |obj| obj }
    end

    str_serializer = Class.new(base_class) do
      attribute(:id) { |obj| obj[0] }
      attribute :chars, serializer: chr_serializer, many: true, exposed: true
    end

    assert_equal(
      {id: "a", chars: [{id: "a"}, {id: "b"}]},
      str_serializer.to_h("ab")
    )
  end

  it "automatically checks if nested relationship is enumerable or single object" do
    chr_serializer = Class.new(base_class) do
      attribute(:id) { |obj| obj }
    end

    int_serializer = Class.new(base_class) do
      attribute(:id) { |obj| obj }
    end

    str_serializer = Class.new(base_class) do
      attribute(:id) { |obj| obj[0] }
      attribute :chars, serializer: chr_serializer, exposed: true, many: true
      attribute :length, serializer: int_serializer, exposed: true, many: false
    end

    assert_equal(
      {id: "a", chars: [{id: "a"}, {id: "b"}], length: {id: 2}},
      str_serializer.to_h("ab")
    )
  end

  it "returns correct structure with has-many relationship with attributes" do
    chr_serializer = Class.new(base_class) do
      attribute(:id) { |obj| obj }
      attribute :next
    end

    str_serializer = Class.new(base_class) do
      attribute(:id) { |obj| obj[0] }
      attribute :chars, serializer: chr_serializer, many: true, exposed: true
    end

    assert_equal(
      {id: "a", chars: [{id: "a", next: "b"}, {id: "b", next: "c"}]},
      str_serializer.to_h("ab")
    )
  end

  it "accepts fields" do
    # All fields are not exposed in this serializers,
    # We will show only attributes provided in `fields` param
    chr_serializer = Class.new(base_class) do
      attribute(:id, exposed: false) { |obj| obj }
      attribute :next, exposed: false
    end

    str_serializer = Class.new(base_class) do
      attribute(:id, exposed: false) { |obj| obj }
      attribute :chars, serializer: chr_serializer, many: true, exposed: false
    end

    assert_equal(
      {chars: [{next: "b"}, {next: "c"}]},
      str_serializer.to_h("ab", fields: "chars(next)")
    )
  end

  describe "adding meta" do
    it "returns correct structure with only meta" do
      empty_serializer = Class.new(base_class)

      assert_equal({meta: {any: :thing}}, empty_serializer.to_h(nil, meta: {any: :thing}))
    end

    it "returns correct structure with overwritten meta key" do
      empty_serializer = Class.new(base_class)
      empty_serializer.meta_key :metadata
      empty_serializer.meta(:foo) { :bar }

      assert_equal({metadata: {foo: :bar}}, empty_serializer.to_h(nil))
      assert_equal({new_meta: {foo: :bar}}, empty_serializer.to_h(nil, meta_key: "new_meta"))
    end

    it "returns correct structure with data and meta" do
      str_serializer = Class.new(base_class) do
        root(:root)
        meta(:version) { "1.2.3" }

        attribute(:id) { |obj| obj }
      end

      assert_equal(
        {root: {id: "1"}, meta: {any: :thing, version: "1.2.3"}},
        str_serializer.to_h("1", meta: {any: :thing})
      )

      assert_equal(
        {root: [{id: "1"}], meta: {any: :thing, version: "1.2.3"}},
        str_serializer.to_h(["1"], meta: {any: :thing})
      )
    end

    it "raises error when trying to add meta to response without root key" do
      str_serializer = Class.new(base_class) do
        attribute(:id) { |obj| obj }
      end

      error = assert_raises(Jat::Error) { str_serializer.to_h("1", meta: {foo: :bar}) }
      assert_equal "Response must have a root key to add metadata", error.message

      error = assert_raises(Jat::Error) { str_serializer.to_h(["1"], meta: {foo: :bar}) }
      assert_equal "Response must have a root key to add metadata", error.message
    end

    it "does not overwrite manually added meta" do
      str_serializer = Class.new(base_class) do
        root(:root)
        meta(:version) { "1.2.3" }

        attribute(:id) { |obj| obj }
      end

      assert_equal(
        {root: {id: "1"}, meta: {version: "2.0.0"}},
        str_serializer.to_h("1", meta: {version: "2.0.0"})
      )
    end

    it "allows to provide lambda as meta key" do
      str_serializer = Class.new(base_class) do
        root(:root)

        meta(:obj) { |obj| obj }
        meta(:context) { |_obj, context| context }
        meta(:time) { Time.new(2020, 1, 1) }

        attribute(:id) { |obj| obj }
      end

      assert_equal(
        {root: {id: "1"}, meta: {obj: "1", context: {foo: :bar}, time: Time.new(2020, 1, 1)}},
        str_serializer.to_h("1", foo: :bar)
      )
    end

    it "does not adds nil meta" do
      str_serializer = Class.new(base_class) do
        root(:root)
        meta(:foo) {}

        attribute(:id) { |obj| obj }
      end

      assert_equal({root: {id: "1"}}, str_serializer.to_h("1", bazz: nil))
    end
  end

  describe ".inspect" do
    it "returns self name" do
      assert_equal "#{base_class}::Response", base_class::Response.inspect
    end
  end
end
