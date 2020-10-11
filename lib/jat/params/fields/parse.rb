# frozen_string_literal: true

class Jat
  module Params
    class Fields
      class Parse
        COMMA = ','

        class << self
          # returns Hash { type => [attr1, attr2] }
          def call(fields)
            return {} unless fields

            fields.each_with_object({}) do |(type, attrs_string), obj|
              attrs = attrs_string.split(COMMA).map!(&:to_sym)
              obj[type] = attrs
            end
          end
        end
      end
    end
  end
end
