# frozen_string_literal: true

class Jat
  # Module in which all Jat plugins should be stored. Also contains logic
  # for registering and loading plugins.
  module Plugins
    @plugins = {}

    # If the registered plugin already exists, use it. Otherwise, require it
    # and return it. This raises a LoadError if such a plugin doesn't exist,
    # or a Jat::Error if it exists but it does not register itself
    # correctly.
    def self.load_plugin(name)
      unless plugin = @plugins[name]
        require "jat/plugins/#{name}"
        raise Error, "plugin #{name} did not register itself correctly in Jat::Plugins" unless plugin = @plugins[name]
      end
      plugin
    end

    def self.load_dependencies(plugin, serializer, *args, **kwargs, &block)
      return unless plugin.respond_to?(:load_dependencies)

      if kwargs.any?
        plugin.load_dependencies(uploader, *args, **kwargs, &block)
      else
        plugin.load_dependencies(uploader, *args, &block)
      end
    end

    # # Delegate call to the plugin in a way that works across Ruby versions.
    # def self.configure(plugin, uploader, *args, **kwargs, &block)
    #   return unless plugin.respond_to?(:configure)

    #   if kwargs.any?
    #     plugin.configure(uploader, *args, **kwargs, &block)
    #   else
    #     plugin.configure(uploader, *args, &block)
    #   end
    # end

    # Register the given plugin with Jat, so that it can be loaded using
    # `Jat.plugin` with a symbol. Should be used by plugin files. Example:
    #
    #     Jat::Plugins.register_plugin(:plugin_name, PluginModule)
    def self.register_plugin(name, mod)
      @plugins[name] = mod
    end
  end
end
