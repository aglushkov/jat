# frozen_string_literal: true

##
# Combines all serializer and its realtions exposed fields into one hash.
# Returns Hash
# {
#   type1 => {
#     serializer: ser1,
#     attributes: [attr1, attr2, ...],
#     relationships: [attr1, attr2, ...]
#   },
#
class Jat
  module Plugins
    module JsonApi
      class ConstructTraversalMap
        attr_reader :jat_class, :result, :exposed, :manually_exposed

        EXPOSED_VALUES = {all: :all, exposed: :exposed, manual: :manual}.freeze

        def initialize(jat_class, exposed, manually_exposed: {})
          @jat_class = jat_class
          @exposed = EXPOSED_VALUES.fetch(exposed)
          @manually_exposed = manually_exposed
        end

        def to_h
          @result = {}
          append(jat_class)
          result
        end

        private

        def append(jat_class)
          type = jat_class.type
          return result if result.key?(type)

          result[type] = {
            serializer: jat_class,
            attributes: [],
            relationships: []
          }

          fill(jat_class)
        end

        def fill(jat_class)
          type = jat_class.type
          type_result = result[type]

          jat_class.attributes.each_value do |attribute|
            next unless expose?(type, attribute)

            fill_attr(type_result, attribute)
          end
        end

        def fill_attr(type_result, attribute)
          name = attribute.name

          if attribute.relation?
            type_result[:relationships] << name
            append(attribute.serializer.call)
          else
            type_result[:attributes] << name
          end
        end

        def expose?(type, attribute)
          return false if attribute.name == :id

          case exposed
          when :all then true
          when :manual then manually_exposed?(type, attribute)
          else attribute.exposed? || manually_exposed?(type, attribute)
          end
        end

        # Return `attribute.exposed?` when type is not provided
        # Checks type is in exposed attributes
        def manually_exposed?(type, attribute)
          return attribute.exposed? unless manually_exposed.key?(type)

          exposed_attrs = manually_exposed[type]
          exposed_attrs.include?(attribute.name)
        end
      end
    end
  end
end
