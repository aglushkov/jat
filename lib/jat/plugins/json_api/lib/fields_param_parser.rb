# frozen_string_literal: true

class Jat
  module Plugins
    module JsonApi
      class FieldsParamParser
        module ClassMethods
          COMMA = ","

          # Returns the Jat class that this FieldsParamParser class is namespaced under.
          attr_accessor :jat_class

          # Since FieldsParamParser is anonymously subclassed when Jat is subclassed,
          # and then assigned to a constant of the Jat subclass, make inspect
          # reflect the likely name for the class.
          def inspect
            "#{jat_class.inspect}::FieldsParamParser"
          end

          def parse(fields)
            return FROZEN_EMPTY_HASH unless fields

            parse_to_nested_hash(fields)
          end

          private

          def parse_to_nested_hash(fields)
            fields.each_with_object({}) do |(type, attrs_string), obj|
              attrs = attrs_string.split(COMMA).map!(&:to_sym)
              obj[type.to_sym] = attrs
            end
          end
        end

        extend ClassMethods
      end
    end
  end
end
