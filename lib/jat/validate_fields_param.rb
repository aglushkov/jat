# frozen_string_literal: true

class Jat
  class InvalidFieldsParam < Error
  end

  class ValidateFieldsParam
    class << self
      def call(serializer, fields)
        fields.each do |type, keys|
          check_fields_type(serializer, type)

          keys.each do |key|
            check_key(serializer, type, key)
          end
        end
      end

      def check_fields_type(serializer, type)
        return if serializer.full_map.key?(type)

        message = "#{serializer} and its children have no requested type `#{type}`"
        raise InvalidFieldsParam, message
      end

      def check_key(serializer, type, key)
        type_data = serializer.full_map.fetch(type)
        type_serializer = type_data.fetch(:serializer).call
        return if type_serializer.keys.key?(key)

        message = "#{type_serializer} has no requested attribute or relationship `#{key}`"
        raise InvalidFieldsParam, message
      end
    end
  end
end
