# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::Preloads::FormatUserPreloads" do
  before { Jat::Plugins.load_plugin(:_preloads) }

  let(:format) { Jat::Plugins::Preloads::FormatUserPreloads }

  it "transforms nil to empty hash" do
    preloads = nil
    assert_equal ({}), format.to_hash(preloads)
  end

  it "transforms false to empty hash" do
    preloads = false
    assert_equal({}, format.to_hash(preloads))
  end

  it "transforms Symbol" do
    preloads = :foo
    assert_equal({foo: {}}, format.to_hash(preloads))
  end

  it "transforms String" do
    preloads = "foo"
    assert_equal({foo: {}}, format.to_hash(preloads))
  end

  it "transforms Hash" do
    preloads = {foo: :bar}
    assert_equal({foo: {bar: {}}}, format.to_hash(preloads))
  end

  it "transforms Array" do
    preloads = %i[foo bar]
    assert_equal({foo: {}, bar: {}}, format.to_hash(preloads))
  end

  it "transforms nested hashes and arrays" do
    preloads = [:foo, {"bar" => "bazz"}, ["bazz"]]
    assert_equal({foo: {}, bar: {bazz: {}}, bazz: {}}, format.to_hash(preloads))

    preloads = {"bar" => "bazz", :foo => [:bar, "bazz"]}
    assert_equal({bar: {bazz: {}}, foo: {bar: {}, bazz: {}}}, format.to_hash(preloads))
  end
end
