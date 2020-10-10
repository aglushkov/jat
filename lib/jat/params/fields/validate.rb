# frozen_string_literal: true

class Jat
  module Params
    class Fields
      class Invalid < Error
      end

      class Validate
        class << self
          def call(serializer, fields)
            fields.each do |type, keys|
              check_fields_type(serializer, type)

              keys.each do |key|
                check_key(serializer, type, key)
              end
            end
          end

          def check_fields_type(serializer, type)
            return if serializer.full_map.key?(type)

            message = "#{serializer} and its children have no requested type `#{type}`"
            raise Invalid, message
          end

          def check_key(serializer, type, key)
            type_data = serializer.full_map.fetch(type)
            type_serializer = type_data.fetch(:serializer)
            return if type_serializer.keys.key?(key)

            message = "#{type_serializer} has no requested attribute or relationship `#{key}`"
            raise Invalid, message
          end
        end
      end
    end
  end
end
