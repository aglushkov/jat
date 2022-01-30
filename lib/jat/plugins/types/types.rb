# frozen_string_literal: true

class Jat
  module Plugins
    module Types
      def self.plugin_name
        :types
      end

      def self.load(jat_class, **_opts)
        jat_class::Attribute.include(InstanceMethods)
      end

      def self.after_load(jat_class, **_opts)
        jat_class.config[:types] = {
          array: ->(value) { Array(value) },
          bool: ->(value) { !!value },
          float: ->(value) { Float(value) },
          hash: ->(value) { Hash(value) },
          int: ->(value) { Integer(value) },
          str: ->(value) { String(value) }
        }
      end

      module InstanceMethods
        def value_block
          return @value_block if instance_variable_defined?(:@value_block)

          original_block = super
          type = opts[:type]
          return original_block unless type

          @value_block = typed_block(type, original_block)
        end

        private

        def typed_block(type, original_block)
          proc do |object, context|
            value = original_block.call(object, context)

            # Type conversion
            if type.is_a?(Symbol)
              self.class.jat_class.config.fetch(:types).fetch(type).call(value)
            else
              type.call(value)
            end
          end
        end
      end
    end

    register_plugin(Types.plugin_name, Types)
  end
end
