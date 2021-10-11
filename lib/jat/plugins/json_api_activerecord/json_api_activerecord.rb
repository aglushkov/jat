# frozen_string_literal: true

require_relative "./lib/preloads"

class Jat
  module Plugins
    module JsonApiActiverecord
      def self.before_load(jat_class, **opts)
        return if jat_class.plugin_used?(:json_api)
        raise Error, "Please load :json_api plugin first"
      end

      def self.load(jat_class, **_opts)
        jat_class.include(InstanceMethods)
      end

      def self.after_load(jat_class, **opts)
        jat_class.plugin :_preloads, **opts
        jat_class.plugin :_activerecord_preloads, **opts
      end

      module InstanceMethods
        def preloads
          @preloads ||= Preloads.call(self)
        end
      end
    end

    register_plugin(:json_api_activerecord, JsonApiActiverecord)
  end
end
