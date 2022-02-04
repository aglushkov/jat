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
      # @param jat_class [Class] Current serializer class
      # @param opts [<Type>] plugin opts
      #
      # @return [void]
      #
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
