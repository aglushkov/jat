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
  class Map
    class Construct
      attr_reader :serializer, :result, :exposed, :manually_exposed

      EXPOSED_VALUES = { all: :all, exposed: :exposed, manual: :manual }.freeze

      def initialize(serializer, exposed, manually_exposed: {})
        @serializer = serializer.()
        @exposed = EXPOSED_VALUES.fetch(exposed)
        @manually_exposed = manually_exposed
      end

      def to_h
        @result = {}
        append(serializer)
        result
      end

      private

      def append(serializer)
        type = serializer.type
        return result if result.key?(type)

        result[type] = {
          serializer: serializer,
          attributes: [],
          relationships: []
        }

        fill(serializer)
      end

      def fill(serializer)
        type = serializer.type
        type_result = result[type]

        serializer.attributes.each_value do |attribute|
          next unless expose?(type, attribute)

          fill_attr(type_result, attribute)
        end
      end

      # :reek:FeatureEnvy
      def fill_attr(type_result, attribute)
        name = attribute.name

        if attribute.relation?
          type_result[:relationships] << name
          append(attribute.serializer.())
        else
          type_result[:attributes] << name
        end
      end

      # :reek:DuplicateMethodCall
      def expose?(type, attribute)
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
