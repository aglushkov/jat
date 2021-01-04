# frozen_string_literal: true

class Jat
  module Params
    class Include
      class Invalid < Error
      end

      class Validate
        class << self
          def call(serializer, includes)
            includes.each do |name, nested_includes|
              attribute = serializer.attributes[name]
              raise_error(serializer, name) if !attribute || !attribute.relation?

              call(attribute.serializer, nested_includes)
            end
          end

          def raise_error(jat_class, name)
            raise Invalid, "#{jat_class} has no `#{name}` relationship"
          end
        end
      end
    end
  end
end
