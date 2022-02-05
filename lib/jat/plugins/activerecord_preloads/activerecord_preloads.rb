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
      # Loads additional plugins
      #
      # @param serializer_class [Class] Current serializer class
      # @param opts [Hash] loaded plugins opts
      #
      # @return [void]
      #
      def self.load(serializer_class, **opts)
        if serializer_class.plugin_used?(:json_api)
          serializer_class.plugin :json_api_activerecord_preloads, **opts
        elsif serializer_class.plugin_used?(:simple_api)
          serializer_class.plugin :simple_api_activerecord_preloads, **opts
        else
          raise Error, "Please load :json_api or :simple_api plugin first"
        end
      end
    end

    register_plugin(ActiverecordPreloads.plugin_name, ActiverecordPreloads)
  end
end
