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

    # Before plugin applied we can make some validations checks, or load plugins
    # that should be loaded before current plugin.
    def self.before_apply(plugin, jat_class, **opts)
      return unless plugin.respond_to?(:before_apply)

      plugin.before_apply(jat_class, **opts)
    end

    # Here we include plugin modules to base class
    def self.apply(plugin, jat_class)
      plugin.apply(jat_class)
    end

    # After applying we can set some config setting or load additional plugins,
    # that should be loaded after current plugin.
    def self.after_apply(plugin, jat_class, **opts)
      return unless plugin.respond_to?(:after_apply)

      plugin.after_apply(jat_class, **opts)
    end
  end
end
