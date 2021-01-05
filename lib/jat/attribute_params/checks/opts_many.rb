# frozen_string_literal: true

class Jat
  class AttributeParams
    module Checks
      class OptsMany < Checks::Base
        def validate
          return unless opts.key?(:many)

          check_type
          check_serializer_exists
        end

        private

        def check_type
          many = opts.fetch(:many)
          return if (many == true) || (many == false)

          error('Attribute option `many` must be boolean')
        end

        def check_serializer_exists
          return if opts.key?(:serializer)

          error('Attribute option `many` can be provided only together with option `serializer`')
        end
      end
    end
  end
end
