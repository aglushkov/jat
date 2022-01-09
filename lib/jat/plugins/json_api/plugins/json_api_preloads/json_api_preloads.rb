# frozen_string_literal: true

require_relative "./lib/preloads"

class Jat
  module Plugins
    module JsonApiPreloads
      def self.plugin_name
        :json_api_preloads
      end

      def self.before_load(jat_class, **opts)
        raise Error, "Please load :json_api plugin first" unless jat_class.plugin_used?(:json_api)

        jat_class.plugin :base_preloads, **opts
      end

      def self.load(jat_class, **_opts)
        jat_class.extend(ClassMethods)
        jat_class.include(InstanceMethods)
      end

      module ClassMethods
        def preloads(context = {})
          new(context).preloads
        end
      end

      module InstanceMethods
        def preloads
          @preloads ||= Preloads.call(self)
        end
      end
    end

    register_plugin(JsonApiPreloads.plugin_name, JsonApiPreloads)
  end
end
