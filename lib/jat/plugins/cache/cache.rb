# frozen_string_literal: true

class Jat
  module Plugins
    module Cache
      def self.plugin_name
        :cache
      end

      def self.before_load(jat_class, **opts)
        jat_class.plugin :to_str, **opts
      end

      def self.load(jat_class, **_opts)
        jat_class.include(InstanceMethods)
      end

      module InstanceMethods
        FORMAT_TO_STR = :to_str
        FORMAT_TO_H = :to_h

        def to_h(object)
          return super if context[:_format] == FORMAT_TO_STR

          context[:_format] = FORMAT_TO_H
          cached(object) { super }
        end

        def to_str(object)
          context[:_format] = FORMAT_TO_STR
          cached(object) { super }
        end

        private

        def cached(object, &block)
          cache = context[:cache]
          return yield unless cache

          cache.call(object, context, &block)
        end
      end
    end

    register_plugin(Cache.plugin_name, Cache)
  end
end
