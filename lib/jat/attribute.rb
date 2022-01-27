# frozen_string_literal: true

require_relative "utils/enum_deep_dup"
require_relative "utils/enum_deep_freeze"

class Jat
  class Attribute
    module InstanceMethods
      attr_reader :params, :opts

      def initialize(name:, opts: {}, block: nil)
        check_block_valid(block)

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

        serializer = opts[:serializer]
        @serializer = serializer.is_a?(Proc) ? serializer.call : serializer
      end

      def block
        return @block if instance_variable_defined?(:@block)

        current_block = params.fetch(:block)
        current_block ||= keyword_block

        @block = current_block
      end

      def value(object, context)
        block.call(object, context)
      end

      private

      def keyword_block
        key_method_name = key
        proc { |object| object.public_send(key_method_name) }
      end

      def check_block_valid(block)
        return unless block

        params = block.parameters
        raise Error, "Block can have 0-2 parameters" if params.count > 2
      end
    end

    extend Jat::JatClass
    include InstanceMethods
  end
end
