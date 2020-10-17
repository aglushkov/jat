# frozen_string_literal: true

require 'jat/opts/check_opts_key'
require 'jat/opts/check_opts_delegate'
require 'jat/opts/check_opts_exposed'
require 'jat/opts/check_opts_serializer'
require 'jat/opts/check_opts_many'
require 'jat/opts/check_opts_includes'

class Jat
  class Opts
    class CheckOpts < CheckBase
      ALLOWED_OPTS = %i[key delegate exposed serializer many includes].freeze

      # :reek:TooManyStatements
      def validate
        CheckOptsKey.(params)
        CheckOptsDelegate.(params)
        CheckOptsExposed.(params)
        CheckOptsSerializer.(params)
        CheckOptsMany.(params)
        CheckOptsIncludes.(params)

        check_extra_keys
      end

      private

      def check_extra_keys
        given_opts = opts.keys
        extra_opts = given_opts - ALLOWED_OPTS

        return if extra_opts.empty?

        error("Attribute options `#{extra_opts.join(', ')}` are not allowed")
      end
    end
  end
end
