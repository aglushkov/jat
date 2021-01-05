# frozen_string_literal: true

require 'jat/attribute'

class Jat
  # Stores all serialized attributes
  class Attributes
    extend Forwardable

    # Jat class where all this attributes assigned
    attr_reader :jat_class

    # Hash that stores attributes { attribute_name => attribute_object }
    attr_reader :attributes

    def_delegators :@attributes, :each, :each_value, :fetch, :key?, :values

    def initialize(jat_class)
      @jat_class = jat_class
      @attributes = {}
    end

    def [](name)
      attributes[name.to_sym]
    end

    def add(params)
      attribute = Attribute.new(jat_class, params)
      attributes[attribute.name] = attribute
      jat_class::Presenter.add_method(attribute.original_name, attribute.block)
      attribute
    end

    # :reek:DuplicateMethodCall
    def refresh
      values.each do |attribute|
        old_name = attribute.name
        attribute.refresh

        # Name can change if key_transform option changed
        @attributes.delete(old_name)
        add(attribute.params)
      end
    end
  end
end
