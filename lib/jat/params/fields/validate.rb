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
              new(serializer, type).validate(attributes_names)
            end
          end
        end

        attr_reader :serializer, :type

        def initialize(serializer, type)
          @serializer = serializer
          @type = type
        end

        def validate(attributes_names)
          check_fields_type
          check_attributes_names(attributes_names)
        end

        private

        def check_fields_type
          return if serializer.full_map.key?(type)

          raise Invalid, "#{serializer} and its children have no requested type `#{type}`"
        end

        def check_attributes_names(attributes_names)
          attributes_names.each do |attribute_name|
            check_attribute_name(attribute_name)
          end
        end

        def check_attribute_name(attribute_name)
          type_data = serializer.full_map.fetch(type)
          type_serializer = type_data.fetch(:serializer)
          return if type_serializer.attributes.key?(attribute_name)

          raise Invalid, "#{type_serializer} has no requested attribute or relationship `#{attribute_name}`"
        end
      end
    end
  end
end
