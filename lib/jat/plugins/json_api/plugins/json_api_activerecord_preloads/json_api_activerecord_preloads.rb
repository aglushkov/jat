# frozen_string_literal: true

class Jat
  module Plugins
    #
    # Plugin is used to automatically preload relations to serialized object
    #
    module JsonApiActiverecordPreloads
      # @return [Symbol] this plugin name
      def self.plugin_name
        :json_api_activerecord_preloads
      end

      # Checks if plugin can be added
      # @return [void]
      def self.before_load(serializer_class, **_opts)
        return if serializer_class.plugin_used?(:json_api)
        raise Error, "Please load :json_api plugin first"
      end

      # Includes additional plugins
      # @return [void]
      def self.load(serializer_class, **opts)
        serializer_class.plugin :json_api_preloads, **opts
        serializer_class.plugin :base_activerecord_preloads, **opts
      end
    end

    register_plugin(JsonApiActiverecordPreloads.plugin_name, JsonApiActiverecordPreloads)
  end
end
