# frozen_string_literal: true

class Jat
  class Opts
    class CheckOptsSerializer < CheckBase
      def validate
        return unless opts.key?(:serializer)

        check(opts[:serializer])
      end

      private

      def check(serializer)
        case serializer
        when Class then check_is_jat(serializer)
        when Proc then check_no_params(serializer)
        else error 'Attribute option `serializer` must be a Jat subclass or a proc'
        end
      end

      def check_is_jat(serializer)
        return if serializer < Jat

        error 'Attribute option `serializer` must be a Jat subclass'
      end

      def check_no_params(serializer)
        return if serializer.parameters.none?

        error 'When attribute option `serializer` is a Proc, it must have no params'
      end
    end
  end
end
