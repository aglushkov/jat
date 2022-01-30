# frozen_string_literal: true

class Jat
  # Exception that raised when loading invalid plugin
  class PluginLoadError < Error; end

  # Module in which all Jat plugins should be stored
  module Plugins
    @plugins = {}

    class << self
      #
      # Registers given plugin to be able to load it using symbol name.
      #
      # @example Register plugin
      #   Jat::Plugins.register_plugin(:plugin_name, PluginModule)
      def register_plugin(name, mod)
        @plugins[name] = mod
      end

      #
      # Loads plugin code and returns plugin core module.
      #
      # @param name [Symbol, Module] plugin name or plugin itself
      #
      # @raise [PluginLoadError] Raises error when plugin was not found
      #
      # @example Find plugin when providing name
      #   Jat::Plugins.find_plugin(:json_api) # => Jat::Plugins::JsonApi
      #
      # @example Find plugin when providing plugin itself
      #   Jat::Plugins.find_plugin(SomePluginModule) # => SomePluginModule
      #
      # @return [Module] Plugin core module
      #
      def find_plugin(name)
        return name if name.is_a?(Module)
        return @plugins[name] if @plugins.key?(name)

        begin
          require_plugin(name)
        rescue PluginLoadError
          name_str = name.to_s
          if name_str.start_with?("json_api")
            require_plugin(name, "/json_api/plugins")
          elsif name_str.start_with?("simple_api")
            require_plugin(name, "/simple_api/plugins")
          elsif name_str.start_with?("base")
            require_plugin(name, "/base")
          else
            raise
          end
        end

        @plugins[name] || raise(PluginLoadError, "Plugin '#{name}' did not register itself correctly")
      end

      private

      def require_plugin(name, prefix = nil)
        require "jat/plugins#{prefix}/#{name}/#{name}"
      rescue LoadError
        raise PluginLoadError, "Plugin '#{name}' does not exist"
      end
    end
  end
end
