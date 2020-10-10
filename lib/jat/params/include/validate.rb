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
              data = serializer.keys[key]
              raise_error(serializer, key) unless data

              nested_serializer = data[:serializer]
              raise_error(serializer, key) unless nested_serializer

              call(nested_serializer.call, nested_includes)
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
