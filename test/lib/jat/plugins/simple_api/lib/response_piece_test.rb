# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::SimpleApi::ResponsePiece" do
  let(:serializer_class) { Class.new(Jat) { plugin :simple_api } }
  let(:described_class) { serializer_class::ResponsePiece }

  describe ".serializer_class=" do
    it "assigns @serializer_class" do
      described_class.serializer_class = :foo
      assert_equal :foo, described_class.instance_variable_get(:@serializer_class)
    end
  end

  describe ".serializer_class" do
    it "returns self @serializer_class" do
      assert_same serializer_class, described_class.instance_variable_get(:@serializer_class)
      assert_same serializer_class, described_class.serializer_class
    end
  end
end
