# frozen_string_literal: true

class Jat
  module Plugins
    module JsonApi
      class IncludeParamParser
        module ClassMethods
          COMMA = ","
          DOT = "."

          def parse(includes_string_param)
            return {} unless includes_string_param

            includes_hash = parse_to_nested_hash(includes_string_param)
            typed_includes(jat_class, includes_hash, {})
          end

          private

          def parse_to_nested_hash(includes_string_param)
            includes_string_param.split(COMMA).each_with_object({}) do |part, obj|
              includes = parse_part(part)
              deep_merge!(obj, includes)
            end
          end

          def typed_includes(jat_class, includes, result)
            includes.each do |included_attr_name, nested_includes|
              add_typed_include(result, jat_class, included_attr_name)

              nested_serializer = jat_class.attributes.fetch(included_attr_name).serializer
              typed_includes(nested_serializer, nested_includes, result)
            end

            result
          end

          def add_typed_include(result, serializer, included_attr_name)
            type = serializer.get_type

            includes = result[type] || []
            includes |= [included_attr_name]

            result[type] = includes
          end

          def parse_part(part)
            val = {}

            part.split(DOT).reverse_each do |inc|
              val = {inc.to_sym => val}
            end

            val
          end

          def deep_merge!(this_hash, other_hash)
            this_hash.merge!(other_hash) do |_key, this_val, other_val|
              deep_merge(this_val, other_val)
            end
          end

          def deep_merge(this_hash, other_hash)
            this_hash.merge(other_hash) do |_key, this_val, other_val|
              deep_merge(this_val, other_val)
            end
          end
        end

        extend Jat::AnonymousClass
        extend ClassMethods
      end
    end
  end
end
