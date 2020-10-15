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
              opts = serializer.attributes[name]
              raise_error(serializer, name) if !opts || !opts.relation?

              call(opts.serializer, nested_includes)
            end
          end

          def raise_error(serializer, name)
            raise Invalid, "#{serializer} has no `#{name}` relationship"
          end
        end
      end
    end
  end
end
