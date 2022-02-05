# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::SimpleApiActiverecord" do
  before do
    @plugin = Jat::Plugins.find_plugin(:simple_api_activerecord)
  end

  it "checks simple_api plugin loaded before" do
    serializer_class = Class.new(Jat)
    error = assert_raises(Jat::Error) { serializer_class.plugin @plugin }
    assert_match(/simple_api/, error.message)
  end

  it "loads other plugins" do
    serializer_class = Class.new(Jat)
    serializer_class.plugin :simple_api
    serializer_class.plugin :simple_api_activerecord

    assert serializer_class.plugin_used?(:simple_api_preloads)
    assert serializer_class.plugin_used?(:base_activerecord_preloads)
  end
end
