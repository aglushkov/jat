# frozen_string_literal: true

class Jat
  module Plugins
    module SimpleApiMapsCache
      def self.plugin_name
        :simple_api_maps_cache
      end

      def self.before_load(serializer_class, **_opts)
        return if serializer_class.plugin_used?(:simple_api)

        raise Error, "Please load :simple_api plugin first"
      end

      def self.load(serializer_class, **_opts)
        serializer_class::Map.extend(MapsCacheClassMethods)
      end

      def self.after_load(serializer_class, **opts)
        serializer_class.config[:cached_maps_count] = opts[:cached_maps_count] || 100
      end

      module MapsCacheClassMethods
        # Caches up to `:cached_maps_count` maps for each serializer.
        # Removes earliest value if new value exceeds limit.
        def maps_cache
          @maps_cache ||= Hash.new do |cache, cache_key|
            cache.shift if cache.length >= serializer_class.config[:cached_maps_count] # protect from memory leak
            cache[cache_key] = Utils::EnumDeepDup.call(yield)
          end
        end

        private

        def construct_map(exposed, fields)
          cache = maps_cache { super }
          cache_key = cache_key(exposed, fields)
          cache[cache_key]
        end

        def cache_key(exposed, fields)
          "exposed:#{exposed}:fields:#{fields}:"
        end
      end
    end

    register_plugin(SimpleApiMapsCache.plugin_name, SimpleApiMapsCache)
  end
end
