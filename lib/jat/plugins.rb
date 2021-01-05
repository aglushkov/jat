# frozen_string_literal: true

class Jat
  module Plugins
    @plugins = {}

    # Register the given plugin with Jat, so that it can be loaded using
    # `Jat.plugin` with a symbol. Should be used by plugin files. Example:
    #
    #     Jat::Plugins.register_plugin(:plugin_name, PluginModule)
    def self.register_plugin(name, mod)
      @plugins[name] = mod
    end

    # If the registered plugin already exists, use it. Otherwise, require it
    # and return it. This raises a LoadError if such a plugin doesn't exist,
    # or a Jat::Error if it exists but it does not register itself
    # correctly.
    def self.load_plugin(name)
      require "jat/plugins/#{name}/#{name}" unless @plugins.key?(name)

      @plugins[name] || raise(Error, "plugin #{name} did not register itself correctly in Jat::Plugins")
    end

    # Delegate call to the plugin in a way that works across Ruby versions.
    def self.before_load(plugin, jat_class, **opts)
      return unless plugin.respond_to?(:before_load)

      plugin.before_load(jat_class, **opts)
    end

    # Delegate call to the plugin in a way that works across Ruby versions.
    def self.after_load(plugin, jat_class, **opts)
      return unless plugin.respond_to?(:after_load)

      plugin.after_load(jat_class, **opts)
    end
  end
end
