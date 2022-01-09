# frozen_string_literal: true

class Jat
  class PluginLoadError < Error; end

  module Plugins
    @plugins = {}

    class << self
      # Registers given plugin to be able to load it using symbol name.
      #
      # Example: Jat::Plugins.register_plugin(:plugin_name, PluginModule)
      def register_plugin(name, mod)
        @plugins[name] = mod
      end

      # If the registered plugin already exists, use it. Otherwise, require
      # and return it. This raises a LoadError if such a plugin doesn't exist,
      # or a Jat::Error if it exists but it does not register itself
      # correctly.
      def find_plugin(name)
        return name if name.is_a?(Module)
        return @plugins[name] if @plugins.key?(name)

        begin
          require_plugin(name)
        rescue PluginLoadError
          if name.start_with?("json_api")
            require_plugin(name, "/json_api/plugins")
          elsif name.start_with?("simple_api")
            require_plugin(name, "/simple_api/plugins")
          elsif name.start_with?("base")
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
