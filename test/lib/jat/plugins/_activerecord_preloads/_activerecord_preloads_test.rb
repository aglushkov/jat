# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::ActiverecordPreloads" do
  let(:jat_class) { Class.new(Jat) { plugin(:_activerecord_preloads) } }
  let(:preloader) { Jat::Plugins::ActiverecordPreloads::Preloader }

  describe "InstanceMethods" do
    it "adds preloads to object in initialize call" do
      obj = "OBJ"
      preloads = "PRELOADS"
      jat_class.expects(:jat_preloads).with(kind_of(jat_class)).returns(preloads)
      preloader.expects(:preload).with(obj, preloads).returns("OBJ_WITH_PRELOADS")

      jat = jat_class.new(obj, {})
      assert_equal("OBJ_WITH_PRELOADS", jat.object)
    end

    it "skips preloadings for nil" do
      object = nil
      jat = jat_class.new(object, {})
      assert_same object, jat.object
    end

    it "skips preloadings for empty array" do
      object = []
      jat = jat_class.new(object, {})
      assert_same object, jat.object
    end

    it "skips preloadings when nothing to preload" do
      object = "OBJECT"
      jat_class.expects(:jat_preloads).with(kind_of(jat_class)).returns({})

      jat = jat_class.new(object, {})
      assert_same object, jat.object
    end
  end
end
