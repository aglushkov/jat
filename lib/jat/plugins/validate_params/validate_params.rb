# frozen_string_literal: true

class Jat
  module Plugins
    module ValidateParams
      def self.plugin_name
        :validate_params
      end

      def self.load(jat_class, **opts)
        if jat_class.plugin_used?(:json_api)
          jat_class.plugin :json_api_validate_params, **opts
        elsif jat_class.plugin_used?(:simple_api)
          jat_class.plugin :simple_api_validate_params, **opts
        else
          raise Error, "Please load :json_api or :simple_api plugin first"
        end
      end
    end

    register_plugin(ValidateParams.plugin_name, ValidateParams)
  end
end
