# frozen_string_literal: true

class Jat
  module Plugins
    module JSON_API
      class Validate
        module ClassMethods
          private

          def validate_all(key, opts, _block)
            super

            if opts[:relationship]
              json_api_validate_relationship_key(key)
              json_api_validate_serializer(opts[:serializer])
            else
              json_api_validate_attribute_key(key)
            end
          end

          def json_api_validate_attribute_key(key)
            return unless json_api_restricted?(key)

            error("Attribute can't have `#{key}` name")
          end

          def json_api_validate_relationship_key(key)
            return unless json_api_restricted?(key)

            error("Relationship can't have `#{key}` name")
          end

          def json_api_validate_serializer(serializer)
            return if serializer.is_a?(Class) && (serializer < Jat)

            error("opts[:serializer] must be a subclass of Jat, #{serializer.inspect} given")
          end

          def json_api_restricted?(key)
            (key == :type) || (key == :id) || (key == 'type') || (key == 'id')
          end
        end
      end
    end
  end
end
