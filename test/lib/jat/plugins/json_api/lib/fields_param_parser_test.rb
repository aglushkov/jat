# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApi::FieldsParamParser" do
  before { Jat::Plugins.find_plugin(:json_api) }

  let(:serializer_class) do
    Class.new(Jat) do
      plugin :json_api
      type :a

      attribute :a1
      attribute :a2
      attribute :a3
    end
  end

  let(:described_class) { serializer_class::FieldsParamParser }

  describe ".parse" do
    it "returns empty hash when parameters not provided" do
      result = described_class.parse(nil)

      assert_equal({}, result)
    end

    it "returns parsed attributes" do
      result = described_class.parse(a: "a1,a2")

      assert_equal({a: %i[a1 a2]}, result)
    end

    it "validates provided attributes" do
      serializer_class.plugin :json_api_validate_params
      error = assert_raises(Jat::Error) { described_class.parse(a: "a1,a2,a3,a4") }
      assert_match(/a4/, error.message)
    end
  end
end
