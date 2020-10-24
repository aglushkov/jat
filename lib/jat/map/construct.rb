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
      attr_reader :serializer, :result, :exposed, :exposed_additionally

      # @exposed can be :all, :none, :default
      def initialize(serializer, exposed, exposed_additionally: nil)
        @serializer = serializer.call
        @exposed = exposed
        @exposed_additionally = exposed_additionally
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
          next if hidden?(type, attribute)

          fill_attr(type_result, attribute)
        end
      end

      # :reek:FeatureEnvy
      def fill_attr(type_result, attribute)
        name = attribute.name

        if attribute.relation?
          type_result[:relationships] << name
          append(attribute.serializer.call)
        else
          type_result[:attributes] << name
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
