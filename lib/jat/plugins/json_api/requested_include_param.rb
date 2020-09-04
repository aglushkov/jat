# frozen_string_literal: true

require 'jat/plugins/json_api/parse_include_param'
require 'jat/plugins/json_api/validate_include_param'

class Jat
  class InvalidIncludeParam < Error
  end

  module Plugins
    module JSON_API
      class RequestedIncludeParam
        class << self
          # returns Hash { type => [key1, key2] }
          def call(serializer, includes_string)
            return {} unless includes_string

            includes = ParseIncludeParam.(includes_string)
            ValidateIncludeParam.(serializer, includes)

            typed_includes(serializer, includes)
          end

          private

          def typed_includes(serializer, includes, result = {})
            includes.each_with_object(result) do |(key, nested_includes), obj|
              type = serializer.type
              obj[type] ||= []
              obj[type] |= [key]

              data = serializer.keys.fetch(key)
              nested_serializer = data.fetch(:serializer)

              if nested_serializer.is_a?(Array)
                nested_serializer.each { |serializer| typed_includes(nested_serializer, nested_includes, obj) }
              else
                typed_includes(nested_serializer, nested_includes, obj)
              end
            end
          end
        end
      end
    end
  end
end
