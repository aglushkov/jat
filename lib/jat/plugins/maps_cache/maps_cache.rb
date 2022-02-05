# frozen_string_literal: true

class Jat
  module Plugins
    module MapsCache
      def self.plugin_name
        :maps_cache
      end

      def self.load(serializer_class, **opts)
        if serializer_class.plugin_used?(:json_api)
          serializer_class.plugin :json_api_maps_cache, **opts
        elsif serializer_class.plugin_used?(:simple_api)
          serializer_class.plugin :simple_api_maps_cache, **opts
        else
          raise Error, "Please load :json_api or :simple_api plugin first"
        end
      end
    end

    register_plugin(MapsCache.plugin_name, MapsCache)
  end
end
