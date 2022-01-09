# frozen_string_literal: true

require_relative "./lib/preloads"

class Jat
  module Plugins
    module SimpleApiPreloads
      def self.plugin_name
        :simple_api_preloads
      end

      def self.before_load(jat_class, **opts)
        raise Error, "Please load :simple_api plugin first" unless jat_class.plugin_used?(:simple_api)

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

    register_plugin(SimpleApiPreloads.plugin_name, SimpleApiPreloads)
  end
end
