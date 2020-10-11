# frozen_string_literal: true
require 'jat/attribute'

class Jat
  class Attributes < Hash
    def [](name)
      super(name.to_sym)
    end

    def []=(name, opts)
      super(name.to_sym, Attribute.new(opts))
    end

    def refresh
      each_value { |attribute| attribute.refresh }
    end
  end
end
