# frozen_string_literal: true

require 'jat/opts/check_name_format'
require 'jat/opts/check_name_reserved'

class Jat
  class Opts
    class CheckName < CheckBase
      def validate
        CheckNameFormat.(params)
        CheckNameReserved.(params)
      end
    end
  end
end
