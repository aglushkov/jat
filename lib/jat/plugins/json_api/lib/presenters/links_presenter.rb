# frozen_string_literal: true

class Jat
  module Presenters
    class LinksPresenter
      module InstanceMethods
        # Presented object
        attr_reader :object

        # Presented context
        attr_reader :context

        def initialize(object, context)
          @object = object
          @context = context
        end
      end

      module ClassMethods
        attr_accessor :jat_class

        def inspect
          "#{jat_class.inspect}::Presenters::LinksPresenter"
        end

        def add_method(name, block)
          # Warning-free method redefinition
          remove_method(name) if method_defined?(name, false)
          define_method(name, &block_without_args(block))
        end

        private

        def block_without_args(block)
          case block.parameters.count
          when 0 then block
          when 1 then -> { instance_exec(object, &block) }
          when 2 then -> { instance_exec(object, context, &block) }
          else raise Error, "Invalid block arguments count"
          end
        end
      end

      extend ClassMethods
      include InstanceMethods
    end
  end
end
