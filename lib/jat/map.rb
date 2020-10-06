# frozen_string_literal: true

# Combines all serializer and its realtions exposed fields into one hash
class Jat
  class Map
    EMPTY_ARRAY = [].freeze
    EMPTY_HASH = {}.freeze

    class << self
      # returns Hash
      # {
      #   type1 => {
      #     serializer: ser1,
      #     attributes: [key1, key2, ...],
      #     relationships: [key1, key2, ...]
      #   },
      #   ...
      # }
      #
      # @map_type can be :all, :none, :exposed
      def call(serializer, map_type, exposed: EMPTY_HASH)
        result = {}
        keys(serializer, map_type, exposed, result)
        result
      end

      private

      def keys(serializer, map_type, exposed, result)
        type = serializer.type
        return result if result.key?(type)

        type_attributes = []
        type_relationships = []

        result[type] = {
          serializer: serializer,
          attributes: type_attributes,
          relationships: type_relationships
        }

        serializer.keys.each do |key, key_data|
          next if skip_key?(serializer, key, key_data, map_type, exposed)

          if key_data[:serializer]
            type_relationships << key
            keys(key_data[:serializer], map_type, exposed, result)
          else
            type_attributes << key
          end
        end
      end

      def skip_key?(serializer, key, key_data, map_type, exposed)
        return false if map_type == :all || exposed.fetch(serializer.type, EMPTY_ARRAY).include?(key)
        return true if map_type == :none

        !key_data[:exposed]
      end
    end
  end
end
