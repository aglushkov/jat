# frozen_string_literal: true

class Jat
  module Plugins
    module Preloads
      def self.plugin_name
        :preloads
      end

      def self.load(jat_class, **opts)
        if jat_class.plugin_used?(:json_api)
          jat_class.plugin :json_api_preloads, **opts
        elsif jat_class.plugin_used?(:simple_api)
          jat_class.plugin :simple_api_preloads, **opts
        else
          raise Error, "Please load :json_api or :simple_api plugin first"
        end
      end
    end

    register_plugin(Preloads.plugin_name, Preloads)
  end
end
