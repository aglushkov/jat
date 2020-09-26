# frozen_string_literal: true

require 'jat/plugins/json_api/parse_include_param'

class Jat
  class InvalidIncludeParam < Error
  end

  module Plugins
    module JSON_API
      class ValidateIncludeParam
        class << self

          def call(serializer, includes)
            includes.each do |key, nested_includes|
              data = serializer.keys[key]
              raise_error(serializer, key) unless data

              nested_serializer = data[:serializer]
              raise_error(serializer, key) unless nested_serializer

              if nested_serializer.is_a?(Array)
                nested_serializer.each { |nested_ser| call(nested_ser, nested_includes) }
              else
                call(nested_serializer, nested_includes)
              end
            end
          end

          def raise_error(serializer, key)
            raise InvalidIncludeParam, "#{serializer} has no `#{key}` relationship"
          end
        end
      end
    end
  end
end
