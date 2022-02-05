# frozen_string_literal: true

class Jat
  module Plugins
    module JsonApi
      module Params
        class Include
          class Validate
            class << self
              def call(serializer_class, includes)
                includes.each do |name, nested_includes|
                  attribute = serializer_class.attributes[name]
                  raise_error(serializer_class, name) if !attribute || !attribute.relation?

                  nested_serializer = attribute.serializer
                  call(nested_serializer, nested_includes)
                end
              end

              def raise_error(serializer_class, name)
                raise Error, "#{serializer_class} has no `#{name}` relationship"
              end
            end
          end
        end
      end
    end
  end
end
