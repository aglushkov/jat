# frozen_string_literal: true

class Jat
  module Plugins
    module SimpleApiPreloads
      #
      # Finds relations to preload for provided serializer
      #
      class Preloads
        # Contains Preloads class methods
        module ClassMethods
          #
          # Constructs preloads hash for given serializer
          #
          # @param jat [Jat] Instance of Jat serializer
          #
          # @return [Hash]
          #
          def call(jat)
            result = {}
            append_many(result, jat.class, jat.map)
            result
          end

          private

          def append_many(result, jat_class, keys)
            keys.each do |key, inner_keys|
              attribute = jat_class.attributes.fetch(key)
              preloads = attribute.preloads
              next unless preloads

              append_one(result, jat_class, preloads)
              next if inner_keys.empty?

              path = attribute.preloads_path
              nested_result = nested(result, path)
              nested_serializer = attribute.serializer

              append_many(nested_result, nested_serializer, inner_keys)
            end
          end

          def append_one(result, jat_class, preloads)
            return if preloads.empty?

            preloads = EnumDeepDup.call(preloads)
            merge(result, preloads)
          end

          def merge(result, preloads)
            result.merge!(preloads) do |_key, value_one, value_two|
              merge(value_one, value_two)
            end
          end

          def nested(result, path)
            !path || path.empty? ? result : result.dig(*path)
          end
        end

        extend ClassMethods
      end
    end
  end
end
