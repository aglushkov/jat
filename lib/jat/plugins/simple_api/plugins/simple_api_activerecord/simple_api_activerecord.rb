# frozen_string_literal: true

class Jat
  module Plugins
    #
    # Plugin is used to automatically preload relations to serialized object
    #
    module SimpleApiActiverecord
      # @return [Symbol] this plugin name
      def self.plugin_name
        :simple_api_activerecord
      end

      # Checks if plugin can be added
      # @return [void]
      def self.before_load(serializer_class, **_opts)
        return if serializer_class.plugin_used?(:simple_api)
        raise Error, "Please load :simple_api plugin first"
      end

      # Includes additional plugins
      # @return [void]
      def self.load(serializer_class, **opts)
        serializer_class.plugin :simple_api_preloads, **opts
        serializer_class.plugin :base_activerecord_preloads, **opts
      end
    end

    register_plugin(SimpleApiActiverecord.plugin_name, SimpleApiActiverecord)
  end
end
