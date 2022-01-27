# frozen_string_literal: true

class Jat
  module Plugins
    module JsonApiValidateParams
      class ValidateIncludeParam
        class << self
          def call(jat_class, includes)
            includes.each do |name, nested_includes|
              attribute = jat_class.attributes[name]
              raise_error(jat_class, name) if !attribute || !attribute.relation?

              nested_serializer = attribute.serializer
              call(nested_serializer, nested_includes)
            end
          end

          private

          def raise_error(jat_class, name)
            type = jat_class.get_type
            allowed_relationships = jat_class.attributes.each_value.select(&:relation?).map!(&:name)
            allowed_relationships = "'#{allowed_relationships.join("', '")}'"

            raise JsonApiParamsError, "Type '#{type}' has no included '#{name}' relationship. Existing relationships are: #{allowed_relationships}"
          end
        end
      end
    end
  end
end
