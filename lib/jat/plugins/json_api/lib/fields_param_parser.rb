# frozen_string_literal: true

class Jat
  module Plugins
    module JsonApi
      class FieldsParamParser
        module ClassMethods
          COMMA = ","

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

        extend Jat::AnonymousClass
        extend ClassMethods
      end
    end
  end
end
