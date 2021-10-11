# frozen_string_literal: true

require_relative "./lib/preloads"

class Jat
  module Plugins
    module SimpleApiActiverecord
      def self.before_load(jat_class, **_opts)
        return if jat_class.plugin_used?(:simple_api)
        raise Error, "Please load :simple_api plugin first"
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

    register_plugin(:simple_api_activerecord, SimpleApiActiverecord)
  end
end
