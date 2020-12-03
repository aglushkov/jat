# frozen_string_literal: true

require 'jat/opts/checks/opts_key'
require 'jat/opts/checks/opts_delegate'
require 'jat/opts/checks/opts_exposed'
require 'jat/opts/checks/opts_serializer'
require 'jat/opts/checks/opts_many'
require 'jat/opts/checks/opts_includes'

class Jat
  class Opts
    module Checks
      class Opts < Checks::Base
        ALLOWED_OPTS = %i[key delegate exposed serializer many includes].freeze

        # :reek:TooManyStatements
        def validate
          OptsKey.(params)
          OptsDelegate.(params)
          OptsExposed.(params)
          OptsSerializer.(params)
          OptsMany.(params)
          OptsIncludes.(params)

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
end
