# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApiActiverecord" do
  before do
    @plugin = Jat::Plugins.find_plugin(:json_api_activerecord)
  end

  it "checks json_api plugin loaded before" do
    jat_class = Class.new(Jat)
    error = assert_raises(Jat::Error) { jat_class.plugin @plugin }
    assert_match(/json_api/, error.message)
  end

  it "loads other plugins" do
    jat_class = Class.new(Jat)
    jat_class.plugin :json_api
    jat_class.plugin :json_api_activerecord

    assert jat_class.plugin_used?(:json_api_preloads)
    assert jat_class.plugin_used?(:_activerecord_preloads)
  end
end
