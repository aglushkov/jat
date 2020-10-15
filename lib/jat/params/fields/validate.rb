# frozen_string_literal: true

class Jat
  module Params
    class Fields
      class Invalid < Error
      end

      class Validate
        class << self
          def call(serializer, fields)
            fields.each do |type, attrs|
              check_fields_type(serializer, type)
              check_attrs(serializer, type, attrs)
            end
          end

          def check_fields_type(serializer, type)
            return if serializer.full_map.key?(type)

            message = "#{serializer} and its children have no requested type `#{type}`"
            raise Invalid, message
          end

          def check_attrs(serializer, type, attrs)
            attrs.each do |attr|
              check_attr(serializer, type, attr)
            end
          end

          def check_attr(serializer, type, attr)
            type_data = serializer.full_map.fetch(type)
            type_serializer = type_data.fetch(:serializer)
            return if type_serializer.attrs.key?(attr)

            message = "#{type_serializer} has no requested attribute or relationship `#{attr}`"
            raise Invalid, message
          end
        end
      end
    end
  end
end
