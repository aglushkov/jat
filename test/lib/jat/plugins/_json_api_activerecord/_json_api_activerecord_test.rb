# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApiActiverecord" do
  before do
    @plugin = Jat::Plugins.load_plugin(:_json_api_activerecord)
  end

  it "loads other plugins in after_apply" do
    jat_class = Class.new(Jat)
    jat_class.expects(:plugin).with(:_preloads, foo: :bar)
    jat_class.expects(:plugin).with(:_activerecord_preloads, foo: :bar)

    @plugin.after_apply(jat_class, foo: :bar)
  end

  describe "ClassMethods" do
    it "add .jat_preloads method as a delegator to #{@plugin}::Preloads" do
      jat_class = Class.new(Jat)
      jat_class.plugin @plugin
      jat = jat_class.allocate

      @plugin::Preloads.expects(:call).with(jat).returns("RES")

      assert_equal "RES", jat_class.jat_preloads(jat)
    end
  end
end
