# frozen_string_literal: true

require 'jat/attribute'

class Jat
  # Stores all serialized attributes
  class Attributes
    extend Forwardable
    def_delegators :@attributes, :each, :each_value, :fetch, :key?, :values

    def initialize
      @attributes = {}
    end

    def [](name)
      @attributes[name.to_sym]
    end

    def add(attribute, presenter_class)
      @attributes[attribute.name] = attribute
      add_method(presenter_class, attribute.original_name, attribute.block)
      self
    end

    # :reek:DuplicateMethodCall
    def refresh
      values.each do |attribute|
        old_name = attribute.name
        attribute.refresh

        # name can change after refresh
        @attributes.delete(old_name)
        add(attribute, attribute.jat_class::Presenter)
      end
    end

    def copy_to(subclass)
      each_value do |attribute|
        attribute_copy = attribute.copy_to(subclass)
        subclass.attributes.add(attribute_copy, subclass::Presenter)
      end
    end

    private

    def add_method(presenter_class, method_name, block)
      presenter_class.add_method(method_name, block)
    end
  end
end
