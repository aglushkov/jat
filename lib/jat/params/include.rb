# frozen_string_literal: true

require 'jat/params/include/parse'
require 'jat/params/include/validate'

class Jat
  module Params
    class Include
      class << self
        # returns Hash { type => [attr1, attr2] }
        def call(serializer, includes_string)
          return {} unless includes_string

          includes = Parse.(includes_string)
          Validate.(serializer, includes)

          typed_includes(serializer, includes, {})
        end

        private

        def typed_includes(serializer, includes, result)
          includes.each do |include_name, nested_includes|
            add_include(result, serializer, include_name)

            nested_serializer = serializer.attrs.fetch(include_name).serializer
            typed_includes(nested_serializer, nested_includes, result)
          end

          result
        end

        def add_include(result, serializer, include_name)
          type = serializer.type

          includes = result[type] || []
          includes |= [include_name]

          result[type] = includes
        end
      end
    end
  end
end
