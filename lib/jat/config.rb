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

    module ClassMethods
      # Returns the Jat class that this config class is namespaced under.
      attr_accessor :jat_class

      # Since Config is anonymously subclassed when Jat is subclassed,
      # and then assigned to a constant of the Jat subclass, make inspect
      # reflect the likely name for the class.
      def inspect
        "#{jat_class.inspect}::Config"
      end
    end

    include InstanceMethods
    extend ClassMethods
  end
end
