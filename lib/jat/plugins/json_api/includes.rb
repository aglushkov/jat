# frozen_string_literal: true

# Combines all serializer and its realtions exposed fields into one hash
class Jat
  module Plugins
    module JSON_API
      class Includes
        class << self
          def call(serializer, types_keys, res = {})
            typed_keys.fetch(:attributes).each_with_object(res) do |key, result|
              attrs = serializer.keys[key]
              merge(result, attrs[:includes])
            end

            typed_keys.fetch(:relationships).each_with_object(res) do |key, result|
              attrs = serializer.keys[key]
              includes = attrs[:includes]
              merge(result, attrs[:includes])

              add_nested_includes(result, types_keys, attrs)
            end
          end

          private

          def add_nested_includes(result, types_keys, attrs)
            serializer = attrs.fetch[:serializer]
            serializer = attrs.fetch[:serializer]
            return unless nested_serializer

            nested_field = attrs.fetch(:field)
            nested_result = result.fetch(nested_field, result)
            call(nested_serializer, nested_result)
          end

          def all_keys(serializer, types_keys)
            typed_keys = types_keys.fetch(serializer.type)
            typed_keys.fetch(:attributes) + typed_keys.fetch(:relationships)
          end

          def merge(res, includes)
            return unless includes

            res.merge!(includes) do |_key, current_value, new_value|
              current_value.merge(new_value)
            end
          end
         end
      end
    end
  end
end
