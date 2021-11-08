# frozen_string_literal: true

require_relative "./lib/params_error"
require_relative "./lib/validate_fields_param"
require_relative "./lib/validate_include_param"

class Jat
  module Plugins
    module JsonApiValidateParams
      def self.plugin_name
        :json_api_validate_params
      end

      def self.before_load(jat_class, **_opts)
        return if jat_class.plugin_used?(:json_api)
        raise Error, "Please load :json_api plugin first"
      end

      def self.load(jat_class, **_opts)
        jat_class.extend(ClassMethods)
        jat_class.include(InstanceMethods)

        jat_class::FieldsParamParser.extend(FieldsParamParserClassMethods)
        jat_class::IncludeParamParser.extend(IncludeParamParserClassMethods)
      end

      module InstanceMethods
        def validate
          @validate ||= self.class.validate(context)
        end
      end

      module ClassMethods
        def validate(context)
          # Generate map for current context.
          # Params are valid if no errors were raised
          map(context)
          true
        end
      end

      module IncludeParamParserClassMethods
        private

        def parse_to_nested_hash(*)
          super.tap { |result| ValidateIncludeParam.call(jat_class, result) }
        end
      end

      module FieldsParamParserClassMethods
        private

        def parse_to_nested_hash(*)
          super.tap { |result| ValidateFieldsParam.call(jat_class, result) }
        end
      end
    end

    register_plugin(JsonApiValidateParams.plugin_name, JsonApiValidateParams)
  end
end
