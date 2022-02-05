# frozen_string_literal: true

require_relative "./lib/preloads"

class Jat
  module Plugins
    #
    # Plugin adds .preload method to serializer class methods and instance
    # methods to find relations that must be preloaded
    #
    module SimpleApiPreloads
      # @return [Symbol] plugin name
      def self.plugin_name
        :simple_api_preloads
      end

      #
      # Checks if plugin can be loaded
      #
      # @param serializer_class [Jat] Class that loads plugin
      # @param opts [Hash] Any options
      #
      # @raise [Jat::Error] Raises error if :simple_api plugin is not added
      #
      # @return [void]
      #
      def self.before_load(serializer_class, **opts)
        raise Error, "Please load :simple_api plugin first" unless serializer_class.plugin_used?(:simple_api)

        serializer_class.plugin :base_preloads, **opts
      end

      #
      # Includes plugin modules to current serializer
      #
      # @param serializer_class [Class] current serializer class
      # @param _opts [Hash] plugin opts
      #
      # @return [void]
      #
      def self.load(serializer_class, **_opts)
        serializer_class.extend(ClassMethods)
        serializer_class.include(InstanceMethods)
      end

      # Adds .preloads class method
      module ClassMethods
        #
        # Shows relations that can be preloaded to omit N+1
        #
        # @param context [Hash] Serialization context
        #
        # @return [Hash]
        #
        def preloads(context = {})
          new(context).preloads
        end
      end

      # Adds #preloads instance method
      module InstanceMethods
        # @return [Hash] relations that can be preloaded to omit N+1
        def preloads
          @preloads ||= Preloads.call(self)
        end
      end
    end

    register_plugin(SimpleApiPreloads.plugin_name, SimpleApiPreloads)
  end
end
