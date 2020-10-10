# frozen_string_literal: true

require 'jat/params/include/parse'
require 'jat/params/include/validate'


class Jat
  module Params
    class Include
      class << self
        # returns Hash { type => [key1, key2] }
        def call(serializer, includes_string)
          return {} unless includes_string

          includes = Parse.(includes_string)
          Validate.(serializer, includes)

          typed_includes(serializer, includes)
        end

        private

        def typed_includes(serializer, includes, result = {})
          includes.each_with_object(result) do |(key, nested_includes), obj|
            type = serializer.type
            obj[type] ||= []
            obj[type] |= [key]

            nested_serializer = serializer.keys.fetch(key).serializer
            typed_includes(nested_serializer, nested_includes, obj)
          end
        end
      end
    end
  end
end
