# frozen_string_literal: true

require "forwardable"
require_relative "utils/enum_deep_dup"

class Jat
  class Config
    module InstanceMethods
      extend Forwardable

      attr_reader :opts

      def initialize(opts = {})
        @opts = EnumDeepDup.call(opts)
      end

      def_delegators :@opts, :[], :[]=, :fetch
    end

    include InstanceMethods
    extend Jat::JatClass
  end
end
