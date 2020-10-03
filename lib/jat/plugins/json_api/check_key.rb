# frozen_string_literal: true

class Jat
  module Plugins
    module JSON_API
      class CheckKey
        module ClassMethods
          private

          def check_name(params)
            super

            json_api_check_name(params)
          end

          def json_api_check_name(name:, opts:, **)
            return if json_api_valid?(name.to_sym)

            key_type = opts.key?(:serializer) ? 'Relationship' : 'Attribute'
            error("#{key_type} can't have `#{name}` name")
          end

          def json_api_valid?(name)
            (name != :type) && (name != :id)
          end
        end
      end
    end
  end
end
