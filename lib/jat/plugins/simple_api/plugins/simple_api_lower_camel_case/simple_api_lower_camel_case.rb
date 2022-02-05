# frozen_string_literal: true

class Jat
  module Plugins
    module SimpleApiLowerCamelCase
      def self.plugin_name
        :simple_api_lower_camel_case
      end

      def self.before_load(serializer_class, **_opts)
        raise Error, "Please load :simple_api plugin first" unless serializer_class.plugin_used?(:simple_api)

        serializer_class.plugin :base_lower_camel_case
      end

      def self.load(serializer_class, **_opts)
        serializer_class::Response.include(ResponseInstanceMethods)
      end

      module ResponseInstanceMethods
        private

        def context_metadata
          metadata = super
          return metadata if metadata.empty?

          metadata.transform_keys! { |key| Jat::LowerCamelCaseTransformation.call(key) }
        end
      end
    end

    register_plugin(SimpleApiLowerCamelCase.plugin_name, SimpleApiLowerCamelCase)
  end
end
