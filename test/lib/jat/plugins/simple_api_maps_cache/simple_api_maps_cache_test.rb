# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::SimpleApiMapsCache" do
  before do
    @plugin = Jat::Plugins.find_plugin(:simple_api_maps_cache)
  end

  it "checks simple_api plugin loaded before" do
    jat_class = Class.new(Jat)
    error = assert_raises(Jat::Error) { jat_class.plugin @plugin }
    assert_match(/simple_api/, error.message)
  end

  it "adds config variable how many maps to store per serializer" do
    jat_class = Class.new(Jat)

    @plugin.after_load(jat_class)
    assert_equal(100, jat_class.config[:cached_maps_count]) # default 100

    @plugin.after_load(jat_class, cached_maps_count: 10) # change value via opts
    assert_equal(10, jat_class.config[:cached_maps_count])
  end

  describe "Test maps responses" do
    let(:jat_class) do
      Class.new(Jat) do
        plugin(:simple_api)
        plugin(:simple_api_maps_cache)

        attribute(:attr1)
        attribute(:attr2)
      end
    end

    it "returns same maps when requested with same params" do
      full_map1 = jat_class::Map.call(exposed: :all)
      full_map2 = jat_class::Map.call(exposed: :all)

      exposed_map1 = jat_class::Map.call(exposed: :default)
      exposed_map2 = jat_class::Map.call(exposed: :default)

      current_map1 = jat_class::Map.call(fields: "attr1")
      current_map2 = jat_class::Map.call(fields: "attr1")
      current_map3 = jat_class::Map.call(fields: "attr2")

      assert_same(full_map1, full_map2)
      assert_same(exposed_map1, exposed_map2)
      assert_same(current_map1, current_map2)

      # should not match, fields are not same
      assert !current_map1.equal?(current_map3)
    end

    it "stores different maps keys" do
      # key 1
      jat_class::Map.call(exposed: :all)
      jat_class::Map.call(exposed: :all)

      # key 2
      jat_class::Map.call(exposed: :default)
      jat_class::Map.call(exposed: :default)

      # key 3
      jat_class::Map.call(fields: "attr1")
      jat_class::Map.call(fields: "attr1")

      # key 4
      jat_class::Map.call(fields: "attr2")

      # key 5
      jat_class::Map.call(fields: "attr1,attr2")

      assert_equal 5, jat_class::Map.maps_cache.keys.count
    end

    it "clears old results when there are too many cache keys" do
      jat_class.config[:cached_maps_count] = 1

      full_map1 = jat_class::Map.call(exposed: :all)
      full_map2 = jat_class::Map.call(exposed: :all)

      # ensure maps refer to same object
      assert_same(full_map1, full_map2)

      # replace single possible cache key with another `exposed` map
      jat_class::Map.call(exposed: :default)

      # calculate full map again, it should not match
      full_map3 = jat_class::Map.call(exposed: :all)
      assert !full_map1.equal?(full_map3)
    end
  end
end
