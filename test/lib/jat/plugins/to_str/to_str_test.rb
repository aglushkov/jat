# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::ToStr" do
  let(:serializer_class) do
    new_class = Class.new(Jat)
    new_class.plugin(:to_str)
    new_class.class_exec do
      def to_h(object)
        {object => context}
      end
    end

    new_class
  end

  describe "Jat" do
    describe ".to_str" do
      it "returns json string of to_h" do
        assert_equal '{"obj":"ctx"}', serializer_class.to_str("obj", "ctx")
      end

      it "returns json string of to_h with default empty hash context" do
        assert_equal '{"obj":{}}', serializer_class.to_str("obj")
      end

      it "returns result serialized with given in config serializer" do
        serializer_class.config[:to_str] = ->(data) { data.inspect }
        assert_equal '{"obj"=>"ctx"}', serializer_class.to_str("obj", "ctx")
      end

      it "accepts to_str config option when loading plugin" do
        new_class = Class.new(Jat)
        new_class.plugin(:to_str, to_str: ->(data) { data.inspect })
        new_class.class_exec do
          def to_h(object)
            {object => context}
          end
        end

        assert_equal '{"obj"=>"ctx"}', new_class.to_str("obj", "ctx")
      end
    end

    describe "#to_str" do
      it "returns json string of to_h" do
        assert_equal '{"obj":"ctx"}', serializer_class.new("ctx").to_str("obj")
      end
    end
  end
end
