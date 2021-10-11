# frozen_string_literal: true

class Jat
  module Plugins
    module SimpleApiValidateParams
      class ValidateFieldsParam
        class << self
          def call(jat_class, fields, prev_names = [])
            fields.each do |name, nested_fields|
              attribute = jat_class.attributes[name]

              raise_error(name, prev_names) unless attribute
              next if nested_fields.empty?

              raise_nested_error(name, prev_names, nested_fields) unless attribute.relation?
              nested_serializer = attribute.serializer.call
              call(nested_serializer, nested_fields, prev_names + [name])
            end
          end

          private

          def raise_error(name, prev_names)
            field_name = field_name(name, prev_names)

            raise SimpleApiFieldsError, "Field #{field_name} not exists"
          end

          def raise_nested_error(name, prev_names, nested_fields)
            field_name = field_name(name, prev_names)
            first_nested = nested_fields.keys.first

            raise SimpleApiFieldsError, "Field #{field_name} is not a relationship to add '#{first_nested}' attribute"
          end

          def field_name(name, prev_names)
            res = "'#{name}'"
            res += " ('#{prev_names.join(".")}.#{name}')" if prev_names.any?
            res
          end
        end
      end
    end
  end
end
