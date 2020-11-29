# frozen_string_literal: true

require 'jat/opts/checks/base'
require 'jat/opts/checks/name'
require 'jat/opts/checks/opts'
require 'jat/opts/checks/block'

class Jat
  class Opts
    class Validate
      def self.call(params)
        Checks::Name.(params)
        Checks::Opts.(params)
        Checks::Block.(params)
      end
    end
  end
end
