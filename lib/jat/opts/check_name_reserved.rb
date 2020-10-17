# frozen_string_literal: true

class Jat
  class Opts
    class CheckNameReserved < CheckBase
      RESERVED_NAMES = %i[type id].freeze

      def validate
        return unless RESERVED_NAMES.include?(name.to_sym)

        error("Attribute can't have '#{name}' name, it is reserved")
      end
    end
  end
end
