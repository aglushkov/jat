# frozen_string_literal: true

require_relative "./lib/preloads"

class Jat
  module Plugins
    #
    # Plugin adds .preload method to serializer class methods and instance
    # methods to find relations that must be preloaded
    #
    module JsonApiPreloads
      # @return [Symbol] plugin name
      def self.plugin_name
        :json_api_preloads
      end

      #
      # Checks if plugin can be loaded
      #
      # @param jat_class [Jat] Class that loads plugin
      # @param opts [Hash] Any options
      #
      # @raise [Jat::Error] Raises error if :simple_api plugin is not added
      #
      # @return [void]
      #
      def self.before_load(jat_class, **opts)
        raise Error, "Please load :json_api plugin first" unless jat_class.plugin_used?(:json_api)

        jat_class.plugin :base_preloads, **opts
      end

      #
      # Includes plugin modules to current serializer
      #
      # @param jat_class [Class] current serializer class
      # @param _opts [Hash] plugin opts
      #
      # @return [void]
      #
      def self.load(jat_class, **_opts)
        jat_class.extend(ClassMethods)
        jat_class.include(InstanceMethods)
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

    register_plugin(JsonApiPreloads.plugin_name, JsonApiPreloads)
  end
end
