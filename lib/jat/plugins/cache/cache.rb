# frozen_string_literal: true

class Jat
  module Plugins
    module Cache
      def self.before_apply(jat_class, **opts)
        jat_class.plugin :to_str, **opts
      end

      def self.apply(jat_class)
        jat_class.include(InstanceMethods)
      end

      module InstanceMethods
        FORMAT_TO_STR = :to_str
        FORMAT_TO_H = :to_h

        def to_h
          return super if context[:_format] == FORMAT_TO_STR

          context[:_format] = FORMAT_TO_H
          cached { super }
        end

        def to_str
          context[:_format] = FORMAT_TO_STR
          cached { super }
        end

        private

        def cached(&block)
          cache = context[:cache]
          return yield unless cache

          cache.call(object, context, &block)
        end
      end
    end

    register_plugin(:cache, Cache)
  end
end
