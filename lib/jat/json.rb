# frozen_string_literal: true

class Jat
  class JSON
    module ClassMethods
      def dump(data)
        json_adapter.dump(data)
      end

      private

      def json_adapter
        @json_adapter ||= begin
          require 'json'
          ::JSON
        end
      end
    end

    extend ClassMethods
  end
end
