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

        serializer.attrs.each do |attr, opts|
          next if hidden?(type, attr, opts)

          fill_attr(result, type_result, attr, opts)
        end
      end

      def fill_attr(result, type_result, attr, opts)
        if opts.relation?
          type_result[:relationships] << attr
          append(result, opts.serializer)
        else
          type_result[:attributes] << attr
        end
      end

      def hidden?(type, attr, opts)
        return false if exposed == :all || manually_exposed?(type, attr)
        return true if exposed == :none

        !opts.exposed?
      end

      def manually_exposed?(type, attr)
        return false unless exposed_additionally

        exposed_attrs = exposed_additionally[type]
        return false unless exposed_attrs

        exposed_attrs.include?(attr)
      end
    end
  end
end
