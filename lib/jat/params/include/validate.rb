# frozen_string_literal: true

class Jat
  module Params
    class Include
      class Invalid < Error
      end

      class Validate
        class << self
          def call(serializer, includes)
            includes.each do |key, nested_includes|
              opts = serializer.keys[key]
              raise_error(serializer, key) if !opts || !opts.relation?

              call(opts.serializer, nested_includes)
            end
          end

          def raise_error(serializer, key)
            raise Invalid, "#{serializer} has no `#{key}` relationship"
          end
        end
      end
    end
  end
end
