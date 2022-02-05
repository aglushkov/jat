# frozen_string_literal: true

class Jat
  module Plugins
    module ValidateParams
      def self.plugin_name
        :validate_params
      end

      def self.load(serializer_class, **opts)
        if serializer_class.plugin_used?(:json_api)
          serializer_class.plugin :json_api_validate_params, **opts
        elsif serializer_class.plugin_used?(:simple_api)
          serializer_class.plugin :simple_api_validate_params, **opts
        else
          raise Error, "Please load :json_api or :simple_api plugin first"
        end
      end
    end

    register_plugin(ValidateParams.plugin_name, ValidateParams)
  end
end
