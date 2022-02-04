# frozen_string_literal: true

class Jat
  module Plugins
    #
    # Plugin that automatically loads JsonApiActiverecord or SimpleApiActiverecord plugin.
    # @see Jat::Plugins::JsonApiActiverecord
    # @see Jat::Plugins::SimpleApiActiverecord
    #
    module Activerecord
      # @return [Symbol] plugin name
      def self.plugin_name
        :activerecord
      end

      #
      # Loads additional plugins
      #
      # @param jat_class [Class] Current serializer class
      # @param opts [Hash] loaded plugins opts
      #
      # @return [void]
      #
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
