# frozen_string_literal: true

require_relative "./include/parse"
require_relative "./include/validate"

class Jat
  module Plugins
    module JsonApi
      module Params
        class Include
          class << self
            # returns Hash { type => [attr1, attr2] }
            def call(jat, includes_string)
              return {} unless includes_string

              jat_class = jat.class
              includes = Parse.call(includes_string)
              Validate.call(jat_class, includes)

              typed_includes(jat_class, includes, {})
            end

            private

            def typed_includes(jat_class, includes, result)
              includes.each do |included_attr_name, nested_includes|
                add_include(result, jat_class, included_attr_name)

                nested_serializer = jat_class.attributes.fetch(included_attr_name).serializer.call
                typed_includes(nested_serializer, nested_includes, result)
              end

              result
            end

            def add_include(result, serializer, included_attr_name)
              type = serializer.type

              includes = result[type] || []
              includes |= [included_attr_name]

              result[type] = includes
            end
          end
        end
      end
    end
  end
end
