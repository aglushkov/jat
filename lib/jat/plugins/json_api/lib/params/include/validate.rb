# frozen_string_literal: true

class Jat
  module Plugins
    module JsonApi
      module Params
        class Include
          class Validate
            class << self
              def call(jat_class, includes)
                includes.each do |name, nested_includes|
                  attribute = jat_class.attributes[name]
                  raise_error(jat_class, name) if !attribute || !attribute.relation?

                  nested_serializer = attribute.serializer.call
                  call(nested_serializer, nested_includes)
                end
              end

              def raise_error(jat_class, name)
                raise Error, "#{jat_class} has no `#{name}` relationship"
              end
            end
          end
        end
      end
    end
  end
end
