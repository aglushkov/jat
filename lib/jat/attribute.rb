# frozen_string_literal: true

require_relative "utils/enum_deep_dup"
require_relative "utils/enum_deep_freeze"

class Jat
  #
  # Stores Attribute data
  #
  class Attribute
    #
    # Stores Attribute instance methods
    #
    module InstanceMethods
      # @return [Symbol] Attribute name
      attr_reader :name

      # @return [Hash] Attribute options
      attr_reader :opts

      # @return [Proc] Attribute originally added block
      attr_reader :block

      #
      # Initializes new attribute
      #
      # @param name [Symbol, String] Name of attribute
      #
      # @param opts [Hash] Attribute options
      # @option opts [Symbol] :key Object instance method name to get attribute value
      # @option opts [Boolean] :exposed Configures if we should serialize this attribute by default.
      #  (by default is true for regular attributes and false for relationships)
      # @option opts [Boolean] :many Specifies has_many relationship. By default is detected via object.is_a?(Enumerable)
      # @option opts [Jat, Proc] :serializer Relationship serializer class. Use `proc { MySerializer }` if serializers have cross references.
      #
      # @param block [Proc] Proc that receives object and context and finds attribute value
      #
      def initialize(name:, opts: {}, block: nil)
        check_block_valid(block)

        @name = name.to_sym
        @opts = Utils::EnumDeepDup.call(opts)
        @block = block
      end

      # @return [Symbol] Object method name to will be used to get attribute value unless block provided
      def key
        @key ||= opts.key?(:key) ? opts[:key].to_sym : name
      end

      # Attribute name that will be used in serialized response.
      # Usually it is same as original name, but can be overwritten by plugins.
      # For example plugin :lower_camel_case changes it.
      # @return [Symbol]
      def serialized_name
        @serialized_name ||= name
      end

      # @return [Boolean] Checks if attribute will be exposed
      def exposed?
        return @exposed if instance_variable_defined?(:@exposed)

        @exposed =
          case self.class.jat_class.config[:exposed]
          when :all then opts.fetch(:exposed, true)
          when :none then opts.fetch(:exposed, false)
          else opts.fetch(:exposed, !relation?)
          end
      end

      # @return [Boolean, nil] Attribute initialization :many option
      def many?
        return @many if instance_variable_defined?(:@many)

        @many = opts[:many]
      end

      # @return [Boolean] Checks if attribute is relationship (if :serializer option exists)
      def relation?
        return @relation if instance_variable_defined?(:@relation)

        @relation = opts.key?(:serializer)
      end

      # @return [Jat, nil] Attribute serializer if exists
      def serializer
        return @serializer if instance_variable_defined?(:@serializer)

        serializer = opts[:serializer]
        @serializer = serializer.is_a?(Proc) ? serializer.call : serializer
      end

      # @return [Proc] Proc to find attribute value
      def value_block
        return @value_block if instance_variable_defined?(:@value_block)

        @value_block = block || keyword_block
      end

      #
      # Finds attribute value
      #
      # @param object [Object] Serialized object
      # @param context [Hash, nil] Serialization context
      #
      # @return [Object] Serialized attribute value
      #
      def value(object, context)
        value_block.call(object, context)
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

    extend Jat::AnonymousClass
    include InstanceMethods
  end
end
