# frozen_string_literal: true

class Jat
  class Opts
    module Checks
      class OptsDelegate < Checks::Base
        def validate
          return unless opts.key?(:delegate)

          delegate = opts.fetch(:delegate)
          return if (delegate == true) || (delegate == false)

          error('Attribute option `delegate` must be boolean')
        end
      end
    end
  end
end
