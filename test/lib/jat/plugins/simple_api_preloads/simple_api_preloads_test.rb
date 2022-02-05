# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::SimpleApiPreloads" do
  before do
    @plugin = Jat::Plugins.find_plugin(:simple_api_preloads)
  end

  it "checks simple_api plugin loaded before" do
    serializer_class = Class.new(Jat)
    error = assert_raises(Jat::Error) { serializer_class.plugin @plugin }
    assert_match(/simple_api/, error.message)
  end

  it "loads other plugins in before_load" do
    serializer_class = Class.new(Jat)
    serializer_class.plugin :simple_api

    serializer_class.expects(:plugin).with(:base_preloads, foo: :bar)

    @plugin.before_load(serializer_class, foo: :bar)
  end

  describe "InstanceMethods" do
    it "adds #preloads method as a delegator to #{@plugin}::Preloads" do
      serializer_class = Class.new(Jat)
      serializer_class.plugin :simple_api
      serializer_class.plugin @plugin
      jat = serializer_class.allocate

      @plugin::Preloads.expects(:call).with(jat).returns("RES")

      assert_equal "RES", jat.preloads
    end
  end

  describe "ClassMethods" do
    it "adds .preloads method as a delegator to #{@plugin}::Preloads" do
      serializer_class = Class.new(Jat)
      serializer_class.plugin :simple_api
      serializer_class.plugin @plugin

      jat = serializer_class.allocate
      serializer_class.expects(:new).with("CONTEXT").returns(jat)
      @plugin::Preloads.expects(:call).with(jat).returns("RES")

      assert_equal "RES", serializer_class.preloads("CONTEXT")
    end
  end
end
