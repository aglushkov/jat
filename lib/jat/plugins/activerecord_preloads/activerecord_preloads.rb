# frozen_string_literal: true

class Jat
  module Plugins
    #
    # Plugin that checks used plugins and loads correct Preloader for selected response type
    # @see Jat::Plugins::JsonApiActiverecordPreloader
    # @see Jat::Plugins::SimpleApiActiverecordPreloader
    #
    module ActiverecordPreloads
      # @return [Symbol] plugin name
      def self.plugin_name
        :activerecord_preloads
      end

      #
      # Loads plugin code and additional plugins
      #
      # @param serializer_class [Class<Jat>] Current serializer class
      # @param opts [Hash] loaded plugins opts
      #
      # @return [void]
      #
      def self.load(serializer_class, **opts)
        response_plugin = serializer_class.config[:response_plugin_loaded]
        raise Error, "Please load :json_api or :simple_api plugin first" unless response_plugin

        require_relative "./lib/preloader"

        # Loads :json_api_preloads or :simple_api_preloads plugin
        serializer_class.plugin :"#{response_plugin}_preloads", **opts
        serializer_class.include(InstanceMethods)
      end

      # Overrides Jat classes instance methods
      module InstanceMethods
        #
        # Override original #to_h method
        # @see Jat#to_h
        #
        def to_h(object)
          object = add_preloads(object)
          super
        end

        private

        def add_preloads(obj)
          return obj if obj.nil? || (obj.is_a?(Array) && obj.empty?)

          # preloads() method comes from simple_api_activerecord or json_api_activerecord plugin
          preloads = preloads()
          return obj if preloads.empty?

          Preloader.preload(obj, preloads)
        end
      end
    end

    register_plugin(ActiverecordPreloads.plugin_name, ActiverecordPreloads)
  end
end
