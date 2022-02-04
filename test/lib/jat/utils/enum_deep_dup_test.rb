# frozen_string_literal: true

require "test_helper"

describe Jat::Utils::EnumDeepDup do
  describe ".call" do
    it "makes deep dup of hash" do
      hash = {key1: {key11: {key111: :value111}}, key2: [{key22: {key222: :value222}}]}
      dup = Jat::Utils::EnumDeepDup.call(hash)

      assert_equal hash, dup

      refute_same hash, dup
      refute_same hash[:key1], dup[:key1]
      refute_same hash[:key1][:key11], dup[:key1][:key11]

      refute_same hash[:key2], dup[:key2]
      refute_same hash[:key2][0], dup[:key2][0]
      refute_same hash[:key2][0][:key22], dup[:key2][0][:key22]
    end

    it "does not duplicates non-enumerable objects" do
      hash = {key1: Jat, key2: [-> {}]}
      dup = Jat::Utils::EnumDeepDup.call(hash)

      assert_equal hash, dup
      assert_same hash[:key1], dup[:key1]
      assert_same hash[:key2][0], dup[:key2][0]
    end
  end
end
