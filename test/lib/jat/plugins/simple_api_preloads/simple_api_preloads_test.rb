# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::SimpleApiPreloads" do
  before do
    @plugin = Jat::Plugins.find_plugin(:simple_api_preloads)
  end

  it "checks simple_api plugin loaded before" do
    jat_class = Class.new(Jat)
    error = assert_raises(Jat::Error) { jat_class.plugin @plugin }
    assert_match(/simple_api/, error.message)
  end

  it "loads other plugins in before_load" do
    jat_class = Class.new(Jat)
    jat_class.plugin :simple_api

    jat_class.expects(:plugin).with(:base_preloads, foo: :bar)

    @plugin.before_load(jat_class, foo: :bar)
  end

  describe "InstanceMethods" do
    it "add .preloads method as a delegator to #{@plugin}::Preloads" do
      jat_class = Class.new(Jat)
      jat_class.plugin :simple_api
      jat_class.plugin @plugin
      jat = jat_class.allocate

      @plugin::Preloads.expects(:call).with(jat).returns("RES")

      assert_equal "RES", jat.preloads
    end
  end
end
