# frozen_string_literal: true

require_relative "utils/enum_deep_dup"
require_relative "utils/enum_deep_freeze"

class Jat
  class Attribute
    module InstanceMethods
      attr_reader :params, :opts

      def initialize(name:, opts: {}, block: nil)
        @opts = EnumDeepDup.call(opts)
        @params = EnumDeepFreeze.call(name: name, opts: @opts, block: block)
      end

      # Attribute name that was provided when initializing attribute
      def original_name
        @original_name ||= params.fetch(:name).to_sym
      end

      # Object method name to get attribute value
      def key
        @key ||= opts.key?(:key) ? opts[:key].to_sym : original_name
      end

      # Attribute name that will be used in serialized response
      def name
        @name ||= original_name
      end

      # Checks if attribute is exposed
      def exposed?
        return @exposed if instance_variable_defined?(:@exposed)

        @exposed =
          case self.class.jat_class.config[:exposed]
          when :all then opts.fetch(:exposed, true)
          when :none then opts.fetch(:exposed, false)
          else opts.fetch(:exposed, !relation?)
          end
      end

      def many?
        return @many if instance_variable_defined?(:@many)

        @many = opts[:many]
      end

      def relation?
        return @relation if instance_variable_defined?(:@relation)

        @relation = opts.key?(:serializer)
      end

      def serializer
        return @serializer if instance_variable_defined?(:@serializer)

        @serializer = opts[:serializer]
      end

      def block
        @block ||=
          params.fetch(:block) || begin
            key_method_name = key
            -> { object.public_send(key_method_name) }
          end
      end
    end

    module ClassMethods
      # Returns the Jat class that this Attribute class is namespaced under.
      attr_accessor :jat_class

      # Since Attribute is anonymously subclassed when Jat is subclassed,
      # and then assigned to a constant of the Jat subclass, make inspect
      # reflect the likely name for the class.
      def inspect
        "#{jat_class.inspect}::Attribute"
      end
    end

    extend ClassMethods
    include InstanceMethods
  end
end
