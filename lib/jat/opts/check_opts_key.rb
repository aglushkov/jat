# frozen_string_literal: true

class Jat
  class Opts
    class CheckOptsKey < CheckBase
      def validate
        return unless opts.key?(:key)

        key = opts.fetch(:key)

        check_key_format(key)
        check_block_exists
      end

      private

      def check_key_format(key)
        return if key.is_a?(String) || key.is_a?(Symbol)

        error 'Attribute option `key` can be only string or symbol'
      end

      def check_block_exists
        return unless block

        error 'Attribute option `key` must be omitted when block provided'
      end
    end
  end
end
