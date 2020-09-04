# frozen_string_literal: true

require 'jat/plugins/json_api/parse_fields_param'
require 'jat/plugins/json_api/validate_fields_param'

class Jat
  module Plugins
    module JSON_API
      class RequestedFieldsParam
        class << self
          # returns Hash { type => [key1, key2] }
          def call(serializer, fields)
            parsed_fields = ParseFieldsParam.(fields)
            ValidateFieldsParam.(serializer, parsed_fields)
            parsed_fields
          end
        end
      end
    end
  end
end
