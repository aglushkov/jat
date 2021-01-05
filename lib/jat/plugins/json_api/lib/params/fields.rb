# frozen_string_literal: true

require_relative "./fields/parse"
require_relative "./fields/validate"

class Jat
  module Plugins
    module JsonApi
      module Params
        class Fields
          class << self
            # returns Hash { type => [key1, key2] }
            def call(jat, fields)
              parsed_fields = Parse.call(fields)
              Validate.call(jat, parsed_fields)
              parsed_fields
            end
          end
        end
      end
    end
  end
end
