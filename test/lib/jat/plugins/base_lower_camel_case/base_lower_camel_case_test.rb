# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::BaseLowerCamelCase" do
  let(:jat_class) do
    new_class = Class.new(Jat)
    new_class.plugin(:base_lower_camel_case)
    new_class
  end

  describe "Attribute" do
    describe "#name" do
      it "returns name in lower_camel_case case" do
        attribute = jat_class.attribute(:foo)
        assert :foo, attribute.name

        attribute = jat_class.attribute(:foo_bar)
        assert :fooBar, attribute.name

        attribute = jat_class.attribute(:foo_bar_bazz)
        assert :fooBarBazz, attribute.name
      end
    end
  end
end
