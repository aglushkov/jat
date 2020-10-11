# frozen_string_literal: true

##
# Combines all serializer and its realtions exposed fields into one hash.
# Returns Hash
# {
#   type1 => {
#     serializer: ser1,
#     attributes: [key1, key2, ...],
#     relationships: [key1, key2, ...]
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

        serializer.keys.each do |key, opts|
          next if hidden?(type, key, opts)

          fill_key(result, type_result, key, opts)
        end
      end

      def fill_key(result, type_result, key, opts)
        if opts.relation?
          type_result[:relationships] << key
          append(result, opts.serializer)
        else
          type_result[:attributes] << key
        end
      end

      def hidden?(type, key, opts)
        return false if exposed == :all || manually_exposed?(type, key)
        return true if exposed == :none

        !opts.exposed?
      end

      def manually_exposed?(type, key)
        return false unless exposed_additionally

        exposed_keys = exposed_additionally[type]
        return false unless exposed_keys

        exposed_keys.include?(key)
      end
    end
  end
end
