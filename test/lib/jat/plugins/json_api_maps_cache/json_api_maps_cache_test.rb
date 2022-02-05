# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApiMapsCache" do
  before do
    @plugin = Jat::Plugins.find_plugin(:json_api_maps_cache)
  end

  it "checks json_api plugin loaded before" do
    serializer_class = Class.new(Jat)
    error = assert_raises(Jat::Error) { serializer_class.plugin @plugin }
    assert_match(/json_api/, error.message)
  end

  it "adds config variable how many maps to store per serializer" do
    serializer_class = Class.new(Jat)

    @plugin.after_load(serializer_class)
    assert_equal(100, serializer_class.config[:cached_maps_count]) # default 100

    @plugin.after_load(serializer_class, cached_maps_count: 10) # change value via opts
    assert_equal(10, serializer_class.config[:cached_maps_count])
  end

  describe "Test maps responses" do
    let(:serializer_class) do
      Class.new(Jat) do
        plugin(:json_api)
        plugin(:json_api_maps_cache)

        type :foo

        attribute(:attr1)
        attribute(:attr2)

        relationship(:rel1, serializer: self)
        relationship(:rel2, serializer: self)
      end
    end

    it "returns same maps when requested with same params" do
      full_map1 = serializer_class::Map.call(exposed: :all)
      full_map2 = serializer_class::Map.call(exposed: :all)

      exposed_map1 = serializer_class::Map.call(exposed: :default)
      exposed_map2 = serializer_class::Map.call(exposed: :default)

      current_map1 = serializer_class::Map.call(include: "rel2", fields: {foo: "attr1,rel1"})
      current_map2 = serializer_class::Map.call(include: "rel2", fields: {foo: "attr1,rel1"})

      assert_same(full_map1, full_map2)
      assert_same(exposed_map1, exposed_map2)
      assert_same(current_map1, current_map2)

      # check different maps are not same

      # should not match, include is not same
      current_map3 = serializer_class::Map.call(include: "rel1", fields: {foo: "attr1,rel1"})
      # should not match, fields are not same
      current_map4 = serializer_class::Map.call(include: "rel2", fields: {foo: "attr1,rel2"})

      assert !current_map1.equal?(current_map3)
      assert !current_map1.equal?(current_map4)
      assert !current_map3.equal?(current_map4)
    end

    it "stores different maps keys" do
      # key 1
      serializer_class::Map.call(exposed: :all)
      serializer_class::Map.call(exposed: :all)

      # key 2
      serializer_class::Map.call(exposed: :default)
      serializer_class::Map.call(exposed: :default)

      # key 3
      serializer_class::Map.call(include: "rel2", fields: {foo: "attr1,rel1"})
      serializer_class::Map.call(include: "rel2", fields: {foo: "attr1,rel1"})

      # key 4
      serializer_class::Map.call(include: "rel1", fields: {foo: "attr1,rel1"})

      # key 5
      serializer_class::Map.call(include: "rel2", fields: {foo: "attr1,rel2"})

      assert_equal 5, serializer_class::Map.maps_cache.keys.count
    end

    it "clears old results when there are too many cache keys" do
      serializer_class.config[:cached_maps_count] = 1

      full_map1 = serializer_class::Map.call(exposed: :all)
      full_map2 = serializer_class::Map.call(exposed: :all)

      # ensure maps refer to same object
      assert_same(full_map1, full_map2)

      # replace single possible cache key with another `exposed` map
      serializer_class::Map.call(exposed: :default)

      # calculate full map again, it should not match
      full_map3 = serializer_class::Map.call(exposed: :all)
      assert !full_map1.equal?(full_map3)
    end
  end
end
