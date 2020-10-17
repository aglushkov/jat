# frozen_string_literal: true

class Jat
  class Opts
    class CheckOptsExposed < CheckBase
      def validate
        return unless opts.key?(:exposed)

        exposed = opts.fetch(:exposed)
        return if (exposed == true) || (exposed == false)

        error('Attribute option `exposed` must be boolean')
      end
    end
  end
end
