# frozen_string_literal: true

require "delegate"
require "forwardable"

class Jat
  module Plugins
    #
    # Plugin Presenter adds possibility to use declare Presenter for your objects inside serializer
    #
    #   class User < Jat
    #     plugin :presenter
    #
    #     attribute :name
    #
    #     class Presenter
    #       def name
    #         [first_name, last_name].compact_blank.join(' ')
    #       end
    #     end
    #   end
    module Presenter
      # @return [Symbol] plugin name
      def self.plugin_name
        :presenter
      end

      #
      # Checks one of response type plugins is already loaded. We need to override its ResponsePiece class.
      #
      # @param serializer_class [Class<Jat>] Current serializer class
      # @param _opts [Hash] Loaded plugins options
      #
      # @return [void]
      #
      def self.before_load(serializer_class, **_opts)
        if !serializer_class.plugin_used?(:json_api) && !serializer_class.plugin_used?(:simple_api)
          raise Error, "Please load :json_api or :simple_api plugin first"
        end
      end

      #
      # Loads plugin
      #
      # @param serializer_class [Class<Jat>] Current serializer class
      # @param _opts [Hash] Loaded plugins options
      #
      # @return [void]
      #
      def self.load(serializer_class, **_opts)
        serializer_class.extend(ClassMethods)
        serializer_class::ResponsePiece.include(ResponsePieceInstanceMethods)
      end

      #
      # Adds Presenter to current serializer
      #
      # @param serializer_class [Class<Jat>] Current serializer class
      # @param _opts [Hash] Loaded plugins options
      #
      # @return [void]
      #
      def self.after_load(serializer_class, **_opts)
        presenter_class = Class.new(Presenter)
        presenter_class.serializer_class = serializer_class
        serializer_class.const_set(:Presenter, presenter_class)
      end

      # Presenter class
      class Presenter < SimpleDelegator
        # Presenter instance methods
        module InstanceMethods
          #
          # Delegates all missing methods to serialized object.
          #
          # Creates delegator method after first #method_missing hit to improve
          # performance of following serializations.
          #
          def method_missing(name, *_args, &_block) # rubocop:disable Style/MissingRespondToMissing (base SimpleDelegator class has this method)
            super.tap do
              self.class.def_delegator :__getobj__, name
            end
          end
        end

        extend Jat::Helpers::SerializerClassHelper
        extend Forwardable
        include InstanceMethods
      end

      # Overrides {Jat::ClassMethods}
      module ClassMethods
        #
        # Inherits Presenter when inheriting from current serializer
        #
        # @param subclass [Class<Jat>] subclass
        #
        # @return [void]
        #
        def inherited(subclass)
          presenter_class = Class.new(self::Presenter)
          presenter_class.serializer_class = subclass
          subclass.const_set(:Presenter, presenter_class)

          super
        end

        # Overrides {Jat::ClassMethods#attribute} method, additionally adds method
        # to Presenter to not hit {Jat::Plugins::Presenter::Presenter#method_missing}
        # @see Jat::ClassMethods#attribute
        def attribute(_name, **_opts, &_block)
          super.tap do |attribute|
            self::Presenter.def_delegator(:__getobj__, attribute.key) unless attribute.block
          end
        end
      end

      # Includes methods to override ResponsePiece class
      module ResponsePieceInstanceMethods
        #
        # Replaces serialized object with Presenter.new(object)
        #
        def initialize(*)
          super
          @object = serializer_class::Presenter.new(object)
        end
      end
    end

    register_plugin(Presenter.plugin_name, Presenter)
  end
end
