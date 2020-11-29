# frozen_string_literal: true

class Jat
  class Opts
    module Checks
      class OptsKey < Checks::Base
        def validate
          return unless opts.key?(:key)

          key = opts.fetch(:key)

          check_key_format(key)
          check_block_exists
        end

        private

        def check_key_format(key)
          return if string?(key)

          error 'Attribute option `key` can be only string or symbol'
        end

        def check_block_exists
          return unless block

          error 'Attribute option `key` must be omitted when block provided'
        end

        def string?(key)
          key.is_a?(String) || key.is_a?(Symbol)
        end
      end
    end
  end
end
