# frozen_string_literal: true

require "delegate"
require "forwardable"

class Jat
  module Plugins
    module Presenter
      def self.plugin_name
        :presenter
      end

      def self.before_load(jat_class, **opts)
        if jat_class.plugin_used?(:json_api)
          jat_class.plugin :json_api_preloads, **opts
        elsif jat_class.plugin_used?(:simple_api)
          jat_class.plugin :simple_api_preloads, **opts
        else
          raise Error, "Please load :json_api or :simple_api plugin first"
        end
      end

      def self.load(jat_class, **_opts)
        jat_class.extend(ClassMethods)
        jat_class::ResponsePiece.include(ResponsePieceInstanceMethods)
      end

      def self.after_load(jat_class, **_opts)
        presenter_class = Class.new(Presenter)
        presenter_class.jat_class = jat_class
        jat_class.const_set(:Presenter, presenter_class)
      end

      class Presenter < SimpleDelegator
        module ClassMethods
          # Returns the Jat class that this Presenter class is namespaced under.
          attr_accessor :jat_class

          # Since Presenter is anonymously subclassed when Jat is subclassed,
          # and then assigned to a constant of the Jat subclass, make inspect
          # reflect the likely name for the class.
          def inspect
            "#{jat_class.inspect}::Presenter"
          end
        end

        module InstanceMethods
          # Delegates all missing methods to current object.
          # We create real methods after first missing method.
          # rubocop:disable Style/MissingRespondToMissing (base SimpleDelegator class has this method)
          def method_missing(name, *args, &block)
            super(name, *args, &block).tap do
              self.class.def_delegator :__getobj__, name
            end
          end
          # rubocop:enable Style/MissingRespondToMissing
        end

        extend Forwardable
        extend ClassMethods
        include InstanceMethods
      end

      module ClassMethods
        def attribute(name, **opts, &block)
          # Define attr_accessor in presenter automatically
          super.tap do |attribute|
            self::Presenter.def_delegator(:__getobj__, attribute.key) unless attribute.params[:block]
          end
        end
      end

      module ResponsePieceInstanceMethods
        def initialize(*)
          super
          @object = jat_class::Presenter.new(object)
        end
      end
    end

    register_plugin(Presenter.plugin_name, Presenter)
  end
end
