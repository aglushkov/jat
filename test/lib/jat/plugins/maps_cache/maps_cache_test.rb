# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::MapsCache" do
  it "raises error if no response plugin is loaded" do
    new_class = Class.new(Jat)
    err = assert_raises(Jat::Error) { new_class.plugin :maps_cache }
    assert_equal "Please load :json_api or :simple_api plugin first", err.message
  end

  it "loads simple_api compatible plugin" do
    new_class = Class.new(Jat)
    new_class.plugin :simple_api
    new_class.plugin :maps_cache

    assert new_class.plugin_used?(:simple_api_maps_cache)
  end

  it "loads json_api compatible plugin" do
    new_class = Class.new(Jat)
    new_class.plugin :json_api
    new_class.plugin :maps_cache

    assert new_class.plugin_used?(:json_api_maps_cache)
  end
end
