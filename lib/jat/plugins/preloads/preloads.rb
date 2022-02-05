# frozen_string_literal: true

class Jat
  module Plugins
    # Loads correct plugin to get relationships to preload
    module Preloads
      # @return [Symbol] plugin name
      def self.plugin_name
        :preloads
      end

      #
      # Loads additional plugins
      #
      # @param serializer_class [Class] Current serializer class
      # @param opts [<Type>] plugin opts
      #
      # @return [void]
      #
      def self.load(serializer_class, **opts)
        if serializer_class.plugin_used?(:json_api)
          serializer_class.plugin :json_api_preloads, **opts
        elsif serializer_class.plugin_used?(:simple_api)
          serializer_class.plugin :simple_api_preloads, **opts
        else
          raise Error, "Please load :json_api or :simple_api plugin first"
        end
      end
    end

    register_plugin(Preloads.plugin_name, Preloads)
  end
end
