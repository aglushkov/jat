# frozen_string_literal: true

require 'jat/params/fields/parse'
require 'jat/params/fields/validate'

class Jat
  module Params
    class Fields
      class << self
        # returns Hash { type => [key1, key2] }
        def call(serializer, fields)
          parsed_fields = Parse.(fields)
          Validate.(serializer, parsed_fields)
          parsed_fields
        end
      end
    end
  end
end
