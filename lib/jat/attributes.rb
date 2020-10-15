# frozen_string_literal: true

require 'jat/opts'
require 'jat/attribute'

class Jat
  class Attributes
    extend Forwardable
    def_delegators :@attributes, :each, :each_value, :key?, :fetch

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

    def refresh
      each_value(&:refresh)
    end

    def copy_to(subclass)
      each_value do |attribute|
        attribute_copy = attribute.copy_to(subclass)
        subclass.attributes << attribute_copy
      end
    end
  end
end
