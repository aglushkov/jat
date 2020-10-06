# frozen_string_literal: true

# Combines all serializer and its realtions exposed fields into one hash
class Jat
  class Includes
    class << self
      def call(serializer, types_keys, res = {})
        typed_keys = types_keys.fetch(serializer.type)

        typed_keys.fetch(:attributes).each_with_object(res) do |key, result|
          merge(result, serializer.keys[key][:includes])
        end

        typed_keys.fetch(:relationships).each_with_object(res) do |key, result|
          attrs = serializer.keys[key]
          includes = attrs[:includes]
          next if !includes || includes.empty?

          merge(result, includes)

          # includes can have only one key
          nested_result = result.fetch(includes.keys.first)
          nested_serializer = attrs.fetch(:serializer)

          call(nested_serializer, types_keys, nested_result)
        end
      end

      private

      def merge(res, includes)
        return unless includes

        res.merge!(includes) do |_key, current_value, new_value|
          current_value.merge(new_value)
        end
      end
    end
  end
end
