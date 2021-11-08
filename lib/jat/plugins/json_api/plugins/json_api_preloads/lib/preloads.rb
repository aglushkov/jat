# frozen_string_literal: true

require "set"

class Jat
  module Plugins
    module JsonApiPreloads
      class Preloads
        class << self
          def call(jat)
            new(jat.map).for(jat.class)
          end
        end

        def initialize(current_map)
          @used = Set.new
          @current_map = current_map
        end

        def for(jat_class)
          result = {}
          append(result, jat_class)
          result
        end

        private

        attr_reader :current_map, :used

        def append(result, jat_class)
          attrs = current_map[jat_class.get_type]

          add_attributes(result, jat_class, attrs[:attributes])
          add_attributes(result, jat_class, attrs[:relationships])
        end

        def add_attributes(result, jat_class, attributes_names)
          attributes_names.each do |name|
            next unless used.add?([jat_class, name]) # Protection from recursive preloads

            attribute = jat_class.attributes[name]
            preloads = attribute.preloads
            next unless preloads # we should not add preloads and nested preloads when nil provided

            merge(result, deep_dup(preloads)) unless preloads.empty?
            add_nested_preloads(result, attribute) if attribute.relation?
          end
        end

        def add_nested_preloads(result, attribute)
          path = attribute.preloads_path
          nested_result = nested(result, path)
          nested_serializer = attribute.serializer.call

          append(nested_result, nested_serializer)
        end

        def merge(result, preloads)
          result.merge!(preloads) do |_key, value_one, value_two|
            merge(value_one, value_two)
          end
        end

        def deep_dup(preloads)
          preloads.dup.transform_values! do |nested_preloads|
            deep_dup(nested_preloads)
          end
        end

        def nested(result, path)
          !path || path.empty? ? result : result.dig(*path)
        end
      end
    end
  end
end
