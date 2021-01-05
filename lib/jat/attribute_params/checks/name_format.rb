# frozen_string_literal: true

class Jat
  class AttributeParams
    module Checks
      class NameFormat < Checks::Base
        NAME_REGEXP = /\A[a-zA-Z0-9_-]+\z/.freeze
        CHECK_CHARS = '-_'

        def validate
          check_type
          check_empty
          check_format
        end

        private

        def check_type
          return if name.is_a?(String) || name.is_a?(Symbol)

          error("Attribute name must be a symbol or a string, but #{name.inspect} was given")
        end

        def check_empty
          error 'Attribute name can not be empty' if name.empty?
        end

        def check_format
          check_first_char(name)
          check_last_char(name)

          return if NAME_REGEXP.match?(name)

          error "Attribute name can include only chars a-z, A-Z, 0-9, '-' and '_'"
        end

        def check_first_char(name)
          return unless CHECK_CHARS.include?(name[0])

          error "Attribute name should not start with '-' or '_'"
        end

        def check_last_char(name)
          return unless CHECK_CHARS.include?(name[-1])

          error "Attribute name should not end with '-' or '_'"
        end
      end
    end
  end
end
