# frozen_string_literal: true

require 'jat/opts/checks/name_format'
require 'jat/opts/checks/name_reserved'

class Jat
  class Opts
    module Checks
      class Name < Checks::Base
        def validate
          NameFormat.(params)
          NameReserved.(params)
        end
      end
    end
  end
end
