# frozen_string_literal: true

require_relative "./lib/fields_error"
require_relative "./lib/validate_fields_param"

class Jat
  module Plugins
    module SimpleApiValidateParams
      def self.plugin_name
        :simple_api_validate_params
      end

      def self.before_load(serializer_class, **_opts)
        return if serializer_class.plugin_used?(:simple_api)
        raise Error, "Please load :simple_api plugin first"
      end

      def self.load(serializer_class, **_opts)
        serializer_class.extend(ClassMethods)
        serializer_class.include(InstanceMethods)

        serializer_class::FieldsParamParser.include(FieldsParamParserMethods)
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

      module FieldsParamParserMethods
        def parse(*)
          super.tap { |result| ValidateFieldsParam.call(self.class.serializer_class, result) }
        end
      end
    end

    register_plugin(SimpleApiValidateParams.plugin_name, SimpleApiValidateParams)
  end
end
