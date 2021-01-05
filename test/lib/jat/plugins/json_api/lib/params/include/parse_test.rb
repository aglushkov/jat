# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApi::Params::Include::Parse" do
  before { Jat::Plugins.load_plugin(:json_api) }

  let(:described_class) { Jat::Plugins::JsonApi::Params::Include::Parse }

  it "returns empty hash when param not provided" do
    result = described_class.call(nil)

    assert_equal({}, result)
  end

  it "returns hash when single element" do
    result = described_class.call("foo")

    assert_equal({foo: {}}, result)
  end

  it "returns hash when multiple elements" do
    result = described_class.call("foo,bar,bazz")

    assert_equal({foo: {}, bar: {}, bazz: {}}, result)
  end

  it "returns hash when nested elements" do
    result = described_class.call("foo.bar.bazz")

    assert_equal({foo: {bar: {bazz: {}}}}, result)
  end

  it "returns hash when multiple nested elements" do
    result = described_class.call("foo,bar.bazz,bar.bazzz,test.test1.test2,test.test1.test3")

    assert_equal(
      {
        foo: {},
        bar: {bazz: {}, bazzz: {}},
        test: {test1: {test2: {}, test3: {}}}
      },
      result
    )
  end
end
