# frozen_string_literal: true

require 'jat/opts/check_base'
require 'jat/opts/check_name'
require 'jat/opts/check_opts'
require 'jat/opts/check_block'

class Jat
  class Opts
    class Check < CheckBase
      def validate
        CheckName.(params)
        CheckOpts.(params)
        CheckBlock.(params)
      end
    end
  end
end
