# frozen_string_literal: true

class Jat
  module Plugins
    module JsonApiLowerCamelCase
      def self.before_load(jat_class, **_opts)
        raise Error, "Please load :json_api plugin first" unless jat_class.plugin_used?(:json_api)

        jat_class.plugin :_lower_camel_case
      end

      def self.load(jat_class, **_opts)
        jat_class::Response.include(ResponseInstanceMethods)
      end

      module ResponseInstanceMethods
        private

        def context_attr_transform(*)
          result = super
          return result if result.empty?

          result.transform_keys! { |key| Jat::LowerCamelCaseTransformation.call(key) }
        end
      end
    end

    register_plugin(:json_api_lower_camel_case, JsonApiLowerCamelCase)
  end
end
