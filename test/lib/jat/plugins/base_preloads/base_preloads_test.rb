# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::BasePreloads" do
  let(:jat_class) do
    Class.new(Jat) { plugin(:base_preloads) }
  end

  def attribute(name, opts)
    jat_class.attribute(name, **opts)
  end

  describe "AttributeMethods" do
    it "saves @preloads and @preloads_path after first access" do
      attribute = attribute(:foo, preload: :bar)

      assert_same attribute.preloads, attribute.preloads
      assert_same attribute.preloads_path, attribute.preloads_path
    end

    describe "#preloads" do
      it "returns formatted data provided by user" do
        assert_equal({}, attribute(:foo, preload: {}).preloads)
        assert_equal({}, attribute(:foo, preload: []).preloads)
        assert_equal({some: {}}, attribute(:foo, preload: :some).preloads)
        assert_equal({some: {data: {}}}, attribute(:foo, preload: {some: :data}).preloads)
      end

      it "preloads main key when serializer exists and preloads are not" do
        assert_equal({foo: {}}, attribute(:foo, serializer: jat_class).preloads)
        assert_equal({bar: {}}, attribute(:foo, key: :bar, serializer: jat_class).preloads)
      end

      it "returns nil when requested to preload nil or false" do
        assert_nil attribute(:foo, serializer: jat_class, preload: nil).preloads
        assert_nil attribute(:foo, key: :bar, serializer: jat_class, preload: false).preloads
      end

      it "removes bang (!) from preloads" do
        assert_equal({foo: {}}, attribute(:foo, preload: :foo!).preloads)
      end
    end

    describe "#preloads_path" do
      it "returns path to main resource provided by user" do
        assert_equal([], attribute(:foo, preload: nil).preloads_path)
        assert_equal([], attribute(:foo, preload: {}).preloads_path)
        assert_equal([], attribute(:foo, preload: []).preloads_path)
        assert_equal([:some], attribute(:foo, preload: :some).preloads_path)
        assert_equal(%i[some data], attribute(:foo, preload: {some: :data}).preloads_path)
      end

      it "show path to main key when serializer exists and preloads are not" do
        assert_equal([:foo], attribute(:foo, serializer: jat_class).preloads_path)
        assert_equal([:bar], attribute(:foo, key: :bar, serializer: jat_class).preloads_path)

        # serializer with empty preloads provided
        assert_equal([], attribute(:foo, serializer: jat_class, preload: nil).preloads_path)
        assert_equal([], attribute(:foo, key: :bar, serializer: jat_class, preload: false).preloads_path)
      end

      it "removes bang (!) and construct path to this preload" do
        assert_equal([:some], attribute(:foo, preload: {some!: :data}).preloads_path)
      end
    end
  end
end
