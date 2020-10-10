# frozen_string_literal: true

require 'jat/parse_include_param'

class Jat
  class InvalidIncludeParam < Error
  end

  class ValidateIncludeParam
    class << self
      def call(serializer, includes)
        includes.each do |key, nested_includes|
          data = serializer.keys[key]
          raise_error(serializer, key) unless data

          nested_serializer = data[:serializer]
          raise_error(serializer, key) unless nested_serializer

          call(nested_serializer.call, nested_includes)
        end
      end

      def raise_error(serializer, key)
        raise InvalidIncludeParam, "#{serializer} has no `#{key}` relationship"
      end
    end
  end
end
