# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::BaseActiverecordPreloads" do
  let(:serializer_class) do
    api_test = api_test()

    Class.new(Jat) do
      include api_test
      plugin(:base_activerecord_preloads)
    end
  end

  let(:api_test) do
    Module.new do
      def to_h(object)
        object
      end
    end
  end

  describe "InstanceMethods" do
    it "adds preloads to object when calling to_h" do
      object = "OBJ"
      preloads = "PRELOADS"
      jat = serializer_class.new
      jat.expects(:preloads).returns(preloads)

      Jat::Plugins::BaseActiverecordPreloads::Preloader
        .expects(:preload)
        .with(object, preloads).returns("OBJ_WITH_PRELOADS")

      assert_equal("OBJ_WITH_PRELOADS", jat.to_h(object))
    end

    it "skips preloadings for nil" do
      object = nil
      jat = serializer_class.new

      assert_same object, jat.to_h(object)
    end

    it "skips preloadings for empty array" do
      object = []
      jat = serializer_class.new

      assert_same object, jat.to_h(object)
    end

    it "skips preloadings when nothing to preload" do
      object = "OBJECT"
      jat = serializer_class.new
      jat.expects(:preloads).returns({})

      assert_same object, jat.to_h(object)
    end
  end
end
