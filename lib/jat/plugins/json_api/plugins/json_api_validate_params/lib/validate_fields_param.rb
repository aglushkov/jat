# frozen_string_literal: true

class Jat
  module Plugins
    module JsonApiValidateParams
      class ValidateFieldsParam
        def self.call(jat_class, fields)
          full_map = jat_class.map_full

          fields.each do |type, attributes_names|
            new(type, full_map).validate(attributes_names)
          end
        end

        attr_reader :type, :full_map

        def initialize(type, full_map)
          @type = type
          @full_map = full_map
        end

        def validate(attributes_names)
          check_fields_type
          check_attributes_names(attributes_names)
        end

        private

        def check_fields_type
          return if full_map.key?(type)

          allowed_types = "'#{full_map.keys.join("', '")}'"

          raise JsonApiParamsError, <<~ERROR.strip
            Response does not have resources with type '#{type}'. Existing types are: #{allowed_types}
          ERROR
        end

        def check_attributes_names(attributes_names)
          attributes_names.each do |attribute_name|
            check_attribute_name(attribute_name)
          end
        end

        def check_attribute_name(attribute_name)
          type_data = full_map.fetch(type)
          type_serializer = type_data.fetch(:serializer)
          return if type_serializer.attributes.key?(attribute_name)

          allowed_attributes = "'#{type_serializer.attributes.keys.join("', '")}'"

          raise JsonApiParamsError, <<~ERROR.strip
            No attribute '#{attribute_name}' in resource type '#{type}'. Existing attributes are: #{allowed_attributes}
          ERROR
        end
      end
    end
  end
end
