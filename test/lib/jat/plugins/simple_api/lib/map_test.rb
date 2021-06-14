# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::SimpleApi::Map" do
  before { Jat::Plugins.load_plugin(:simple_api) }

  subject { Jat::Plugins::SimpleApi::Map.call(jat) }

  let(:jat_class) do
    Class.new(Jat) do
      plugin :simple_api

      attribute :a1
      attribute :a2
      attribute :a3, exposed: false
      attribute :a4, exposed: false
      attribute :a5, exposed: false
    end
  end

  let(:jat) { jat_class.new(nil, {**params, **context}) }
  let(:params) { {} }
  let(:context) { {} }

  describe "when no params given" do
    it "returns map of exposed by default fields" do
      assert_equal({a1: {}, a2: {}}, subject)
    end
  end

  describe "when fields given" do
    let(:params) { {params: {fields: "a2,a3,a4"}} }

    it "constructs map with default and provided fields" do
      assert_equal({a1: {}, a2: {}, a3: {}, a4: {}}, subject)
    end
  end

  describe "with `exposed: all` context" do
    let(:context) { {exposed: :all} }

    it "constructs map with all fields" do
      assert_equal({a1: {}, a2: {}, a3: {}, a4: {}, a5: {}}, subject)
    end
  end

  describe "with `exposed: none` context" do
    let(:params) { {params: {fields: "a2,a3,a4"}} }
    let(:context) { {exposed: :none} }

    it "constructs map with only requested fields" do
      assert_equal({a2: {}, a3: {}, a4: {}}, subject)
    end
  end
end
