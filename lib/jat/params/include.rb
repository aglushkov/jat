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

          typed_includes(serializer, includes)
        end

        private

        def typed_includes(serializer, includes, result = {})
          includes.each_with_object(result) do |(attr, nested_includes), obj|
            type = serializer.type
            obj[type] ||= []
            obj[type] |= [attr]

            nested_serializer = serializer.attrs.fetch(attr).serializer
            typed_includes(nested_serializer, nested_includes, obj)
          end
        end
      end
    end
  end
end
