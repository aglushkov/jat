# frozen_string_literal: true

require 'jat/opts/checks/name_format'

class Jat
  class Opts
    module Checks
      class Name < Checks::Base
        def validate
          NameFormat.(params)
        end
      end
    end
  end
end
