# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApi::ResponsePiece" do
  let(:jat_class) { Class.new(Jat) { plugin :json_api } }
  let(:described_class) { jat_class::ResponsePiece }

  describe ".jat_class=" do
    it "assigns @jat_class" do
      described_class.jat_class = :foo
      assert_equal :foo, described_class.instance_variable_get(:@jat_class)
    end
  end

  describe ".jat_class" do
    it "returns self @jat_class" do
      assert_same jat_class, described_class.instance_variable_get(:@jat_class)
      assert_same jat_class, described_class.jat_class
    end
  end
end
