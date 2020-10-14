# frozen_string_literal: true

require 'jat/opts'
require 'jat/attribute'

class Jat
  class Attributes < Hash
    def [](name)
      super(name.to_sym)
    end

    def []=(name, attr)
      super(name.to_sym, attr)
    end

    def refresh
      each_value(&:refresh)
    end

    def copy_to(subclass)
      each do |key, attr|
        attr_copy = attr.copy_to(subclass)
        subclass.attrs[key] = attr_copy
      end
    end
  end
end
