# frozen_string_literal: true

require_relative "./lib/preloader"

class Jat
  module Plugins
    module BaseActiverecordPreloads
      def self.plugin_name
        :base_activerecord_preloads
      end

      def self.load(serializer_class, **_opts)
        serializer_class.include(InstanceMethods)
      end

      module InstanceMethods
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

    register_plugin(BaseActiverecordPreloads.plugin_name, BaseActiverecordPreloads)
  end
end
