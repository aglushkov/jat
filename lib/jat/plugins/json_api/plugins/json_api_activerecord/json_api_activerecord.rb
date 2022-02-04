# frozen_string_literal: true

class Jat
  module Plugins
    #
    # Plugin is used to automatically preload relations to serialized object
    #
    module JsonApiActiverecord
      # @return [Symbol] this plugin name
      def self.plugin_name
        :json_api_activerecord
      end

      # Checks if plugin can be added
      # @return [void]
      def self.before_load(jat_class, **_opts)
        return if jat_class.plugin_used?(:json_api)
        raise Error, "Please load :json_api plugin first"
      end

      # Includes additional plugins
      # @return [void]
      def self.load(jat_class, **opts)
        jat_class.plugin :json_api_preloads, **opts
        jat_class.plugin :base_activerecord_preloads, **opts
      end
    end

    register_plugin(JsonApiActiverecord.plugin_name, JsonApiActiverecord)
  end
end
