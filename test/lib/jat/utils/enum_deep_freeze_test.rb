# frozen_string_literal: true

require "test_helper"

describe Jat::EnumDeepFreeze do
  describe ".call" do
    it "deeply freezes provided hash" do
      hash = {key1: {key11: {key111: :value111}}, key2: [{key22: {key222: :value222}}]}
      Jat::EnumDeepFreeze.call(hash)

      assert hash.frozen?
      assert hash[:key1].frozen?
      assert hash[:key1][:key11].frozen?

      assert hash[:key2].frozen?
      assert hash[:key2][0].frozen?
      assert hash[:key2][0][:key22].frozen?
    end

    it "does not freezes non-enumerable objects" do
      hash = {key1: Jat, key2: [-> {}]}
      Jat::EnumDeepFreeze.call(hash)

      refute hash[:key1].frozen?
      refute hash[:key2][0].frozen?
    end
  end
end
