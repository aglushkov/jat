# frozen_string_literal: true

class Jat
  class Opts
    class CheckBase
      attr_reader :params, :name, :opts, :block

      def self.call(params)
        new(params).validate
      end

      def initialize(params)
        @params = params
        @name = params.fetch(:name)
        @opts = params.fetch(:opts)
        @block = params.fetch(:block)
      end

      private

      def error(error_message)
        raise Jat::Error, error_message
      end
    end
  end
end
