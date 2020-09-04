# frozen_string_literal: true

class Jat
  module Plugins
    module JSON_API
      class ParseFieldsParam
        COMMA = ','

        class << self
          # returns Hash { type => [key1, key2] }
          def call(fields)
            return {} unless fields

            fields.each_with_object({}) do |(type, keys_string), obj|
              keys = keys_string.split(COMMA).map!(&:to_sym)
              obj[type] = keys
            end
          end
        end
      end
    end
  end
end
