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
  module Services
    class ConstructMap
      attr_reader :serializer, :exposed, :exposed_additionally

      # @exposed can be :all, :none, :default
      def initialize(exposed, exposed_additionally: nil)
        @exposed = exposed
        @exposed_additionally = exposed_additionally
      end

      def for(serializer)
        result = {}
        append(result, serializer)
        result
      end

      private

      def append(result, serializer)
        type = serializer.type
        return result if result.key?(type)

        result[type] = {
          serializer: serializer,
          attributes: [],
          relationships: []
        }

        fill(result, serializer)
      end

      def fill(result, serializer)
        type = serializer.type
        type_result = result[type]

        serializer.attributes.each_value do |attribute|
          next if hidden?(type, attribute)

          fill_attr(result, type_result, attribute)
        end
      end

      def fill_attr(result, type_result, attribute)
        attribute_name = attribute.name

        if attribute.relation?
          type_result[:relationships] << attribute_name
          append(result, attribute.serializer)
        else
          type_result[:attributes] << attribute_name
        end
      end

      def hidden?(type, attribute)
        return false if exposed == :all || manually_exposed?(type, attribute)
        return true if exposed == :none

        !attribute.exposed?
      end

      def manually_exposed?(type, attribute)
        return false unless exposed_additionally

        exposed_attrs = exposed_additionally[type]
        return false unless exposed_attrs

        exposed_attrs.include?(attribute.name)
      end
    end
  end
end
