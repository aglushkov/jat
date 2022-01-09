# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApi::ResponsePiece" do
  let(:jat_class) { Class.new(Jat) { plugin :json_api } }

  describe ".inspect" do
    it "returns self name" do
      assert_equal "#{jat_class}::ResponsePiece", jat_class::ResponsePiece.inspect
    end
  end
end
