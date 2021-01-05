# frozen_string_literal: true

require 'jat/attribute_params/checks/name_format'

class Jat
  class AttributeParams
    module Checks
      class Name < Checks::Base
        def validate
          NameFormat.(params)
        end
      end
    end
  end
end
