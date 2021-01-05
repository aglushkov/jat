# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::Preloads::PreloadsWithPath" do
  before { Jat::Plugins.load_plugin(:_preloads) }

  let(:described_class) { Jat::Plugins::Preloads::PreloadsWithPath }

  it "returns provided preloads and path to last value" do
    preloads = {a: {b: {c: {}}, d: {}}, e: {}}
    new_preloads, path = described_class.call(preloads)

    assert_equal({a: {b: {c: {}}, d: {}}, e: {}}, new_preloads)
    assert_equal(%i[e], path)
  end

  it "returns provided preloads and path to marked with `!` value" do
    preloads = {a: {b!: {c: {}}, d: {}}, e: {}}
    new_preloads, path = described_class.call(preloads)

    assert_equal({a: {b: {c: {}}, d: {}}, e: {}}, new_preloads)
    assert_equal(%i[a b], path)
  end

  it "returns empty preloads and path when empty hash provided" do
    preloads = {}
    new_preloads, path = described_class.call(preloads)

    assert_equal({}, new_preloads)
    assert_equal([], path)
  end
end
