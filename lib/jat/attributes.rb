# frozen_string_literal: true

require 'jat/attribute'

class Jat
  # Stores all serialized attributes
  class Attributes
    extend Forwardable

    attr_reader :jat_class

    def_delegators :@attributes, :each, :each_value, :fetch, :key?, :values

    def initialize(jat_class)
      @jat_class = jat_class
      @attributes = {}
    end

    def [](name)
      @attributes[name.to_sym]
    end

    def add(params)
      attribute = Attribute.new(jat_class, params)
      @attributes[attribute.name] = attribute
      add_method(jat_class::Presenter, attribute.original_name, attribute.block)
      attribute
    end

    # :reek:DuplicateMethodCall
    def refresh
      values.each do |attribute|
        old_name = attribute.name
        attribute.refresh

        # name can change after refresh
        @attributes.delete(old_name)
        add(attribute.params)
      end
    end

    private

    def add_method(presenter_class, method_name, block)
      presenter_class.add_method(method_name, block)
    end
  end
end
