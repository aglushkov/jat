# frozen_string_literal: true

class Jat
  class Opts
    class CheckBlock < CheckBase
      def validate
        return unless block

        block.parameters.each_with_index do |(param_type, _), index|
          next if (index < 2) && ((param_type == :opt) || (param_type == :req))

          error 'Attribute block must include 1 or 2 args (required object, optional params)'
        end
      end
    end
  end
end
