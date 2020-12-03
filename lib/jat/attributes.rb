# frozen_string_literal: true

require 'jat/attribute'

class Jat
  class Attributes
    extend Forwardable
    def_delegators :@attributes, :each, :each_value, :fetch, :key?, :values

    def initialize
      @attributes = {}
    end

    def [](name)
      @attributes[name.to_sym]
    end

    def <<(attribute)
      @attributes[attribute.name] = attribute
      self
    end

    # :reek:DuplicateMethodCall
    def refresh
      values.each do |attribute|
        old_name = attribute.name
        attribute.refresh

        # name can change after refresh
        new_name = attribute.name
        @attributes[new_name] = @attributes.delete(old_name)
      end
    end

    def copy_to(subclass)
      each_value do |attribute|
        attribute_copy = attribute.copy_to(subclass)
        subclass.attributes << attribute_copy
      end
    end
  end
end
