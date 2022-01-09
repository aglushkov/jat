# frozen_string_literal: true

class Jat
  module Plugins
    module SimpleApiActiverecord
      def self.plugin_name
        :simple_api_activerecord
      end

      def self.before_load(jat_class, **_opts)
        return if jat_class.plugin_used?(:simple_api)
        raise Error, "Please load :simple_api plugin first"
      end

      def self.load(jat_class, **opts)
        jat_class.plugin :simple_api_preloads, **opts
        jat_class.plugin :base_activerecord_preloads, **opts
      end
    end

    register_plugin(SimpleApiActiverecord.plugin_name, SimpleApiActiverecord)
  end
end
