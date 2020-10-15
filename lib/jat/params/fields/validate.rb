# frozen_string_literal: true

class Jat
  module Params
    class Fields
      class Invalid < Error
      end

      class Validate
        class << self
          def call(serializer, fields)
            fields.each do |type, attributes_names|
              check_fields_type(serializer, type)
              check_attributes_names(serializer, type, attributes_names)
            end
          end

          def check_fields_type(serializer, type)
            return if serializer.full_map.key?(type)

            message = "#{serializer} and its children have no requested type `#{type}`"
            raise Invalid, message
          end

          def check_attributes_names(serializer, type, attributes_names)
            attributes_names.each do |attribute_name|
              check_attribute_name(serializer, type, attribute_name)
            end
          end

          def check_attribute_name(serializer, type, attribute_name)
            type_data = serializer.full_map.fetch(type)
            type_serializer = type_data.fetch(:serializer)
            return if type_serializer.attributes.key?(attribute_name)

            message = "#{type_serializer} has no requested attribute or relationship `#{attribute_name}`"
            raise Invalid, message
          end
        end
      end
    end
  end
end
