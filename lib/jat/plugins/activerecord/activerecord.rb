# frozen_string_literal: true

class Jat
  module Plugins
    module Activerecord
      def self.plugin_name
        :activerecord
      end

      def self.load(jat_class, **opts)
        if jat_class.plugin_used?(:json_api)
          jat_class.plugin :json_api_activerecord, **opts
        elsif jat_class.plugin_used?(:simple_api)
          jat_class.plugin :simple_api_activerecord, **opts
        else
          raise Error, "Please load :json_api or :simple_api plugin first"
        end
      end
    end

    register_plugin(Activerecord.plugin_name, Activerecord)
  end
end
