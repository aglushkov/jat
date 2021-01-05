# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApiActiverecord" do
  it "loads other plugins in after_load" do
    jat_class = Class.new(Jat)

    plugin = Jat::Plugins.load_plugin(:_json_api_activerecord)

    jat_class.expects(:plugin).with(:_preloads, {})
    jat_class.expects(:plugin).with(:_activerecord_preloads, {})

    Jat::Plugins.after_load(plugin, jat_class)
  end

  it "adds jat_preloads method that calls Preloads" do
    jat_class = Class.new(Jat) { plugin(:_json_api_activerecord) }
    jat = jat_class.allocate
    Jat::Plugins::JsonApiActiverecord::Preloads.expects(:call).with(jat).returns("RES")

    assert_equal "RES", jat_class.jat_preloads(jat)
  end
end
