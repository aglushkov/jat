# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApi::Params::Fields::Parse" do
  before { Jat::Plugins.load_plugin(:json_api) }

  let(:described_class) { Jat::Plugins::JsonApi::Params::Fields::Parse }

  it "returns empty hash when param not provided" do
    result = described_class.call(nil)
    assert_equal({}, result)
  end

  it "returns hash with parsed keys" do
    result = described_class.call(a: "a1,a2", b: "b1")
    assert_equal({a: %i[a1 a2], b: %i[b1]}, result)
  end

  it "symbolizes types" do
    result = described_class.call("a" => "a1,a2", "b" => "b1")
    assert_equal({a: %i[a1 a2], b: %i[b1]}, result)
  end
end
