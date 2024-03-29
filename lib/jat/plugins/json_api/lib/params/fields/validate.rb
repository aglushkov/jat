# frozen_string_literal: true

class Jat
  module Plugins
    module JsonApi
      module Params
        class Fields
          class Validate
            class << self
              def call(jat, fields)
                full_map = jat.maps.full

                fields.each do |type, attributes_names|
                  new(jat, type, full_map).validate(attributes_names)
                end
              end
            end

            attr_reader :jat, :type, :full_map

            def initialize(jat, type, full_map)
              @jat = jat
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

              raise Error, "#{jat.class} and its children have no requested type `#{type}`"
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

              raise Error, "#{type_serializer} has no requested attribute or relationship `#{attribute_name}`"
            end
          end
        end
      end
    end
  end
end
