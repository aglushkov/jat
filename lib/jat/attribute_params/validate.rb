# frozen_string_literal: true

require 'jat/attribute_params/checks/base'
require 'jat/attribute_params/checks/name'
require 'jat/attribute_params/checks/opts'
require 'jat/attribute_params/checks/block'

class Jat
  class AttributeParams
    class Validate
      def self.call(params)
        Checks::Name.(params)
        Checks::Opts.(params)
        Checks::Block.(params)
      end
    end
  end
end
