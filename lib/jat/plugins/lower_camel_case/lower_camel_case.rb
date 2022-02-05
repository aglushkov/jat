# frozen_string_literal: true

class Jat
  module Plugins
    module LowerCamelCase
      def self.plugin_name
        :lower_camel_case
      end

      def self.load(serializer_class, **opts)
        if serializer_class.plugin_used?(:json_api)
          serializer_class.plugin :json_api_lower_camel_case, **opts
        elsif serializer_class.plugin_used?(:simple_api)
          serializer_class.plugin :simple_api_lower_camel_case, **opts
        else
          raise Error, "Please load :json_api or :simple_api plugin first"
        end
      end
    end

    register_plugin(LowerCamelCase.plugin_name, LowerCamelCase)
  end
end
