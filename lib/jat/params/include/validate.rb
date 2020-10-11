# frozen_string_literal: true

class Jat
  module Params
    class Include
      class Invalid < Error
      end

      class Validate
        class << self
          def call(serializer, includes)
            includes.each do |attr, nested_includes|
              opts = serializer.attrs[attr]
              raise_error(serializer, attr) if !opts || !opts.relation?

              call(opts.serializer, nested_includes)
            end
          end

          def raise_error(serializer, attr)
            raise Invalid, "#{serializer} has no `#{attr}` relationship"
          end
        end
      end
    end
  end
end
