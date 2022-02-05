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

    assert new_class.plugin_used?(:simple_api_preloads)
  end

  it "loads json_api compatible plugin" do
    new_class = Class.new(Jat)
    new_class.plugin :json_api
    new_class.plugin :activerecord_preloads

    assert new_class.plugin_used?(:json_api_preloads)
  end

  describe "InstanceMethods" do
    let(:serializer_class) do
      Class.new(Jat) do
        plugin :simple_api
        plugin :activerecord_preloads

        attribute :itself
      end
    end

    it "adds preloads to object when calling to_h" do
      object = "OBJ"
      preloads = "PRELOADS"
      jat = serializer_class.new
      jat.expects(:preloads).returns(preloads)

      Jat::Plugins::ActiverecordPreloads::Preloader
        .expects(:preload)
        .with(object, preloads).returns("OBJ_WITH_PRELOADS")

      assert_equal("OBJ_WITH_PRELOADS", jat.to_h(object)[:itself])
    end

    it "skips preloading for nil" do
      object = nil
      jat = serializer_class.new

      assert_same object, jat.to_h(object)[:itself]
    end

    it "skips preloading for empty array" do
      object = []
      jat = serializer_class.new(many: false)
      assert_same object, jat.to_h(object)[:itself]
    end

    it "skips preloading when nothing to preload" do
      object = "OBJECT"
      jat = serializer_class.new
      jat.expects(:preloads).returns({})

      assert_same object, jat.to_h(object)[:itself]
    end
  end
end
