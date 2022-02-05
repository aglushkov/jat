# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::ActiverecordPreloads" do
  it "raises error if no response plugin is loaded" do
    new_class = Class.new(Jat)
    err = assert_raises(Jat::Error) { new_class.plugin :activerecord_preloads }
    assert_equal "Please load :json_api or :simple_api plugin first", err.message
  end

  it "loads simple_api compatible plugin" do
    new_class = Class.new(Jat)
    new_class.plugin :simple_api
    new_class.plugin :activerecord_preloads

    assert new_class.plugin_used?(:simple_api_activerecord_preloads)
  end

  it "loads json_api compatible plugin" do
    new_class = Class.new(Jat)
    new_class.plugin :json_api
    new_class.plugin :activerecord_preloads

    assert new_class.plugin_used?(:json_api_activerecord_preloads)
  end
end
