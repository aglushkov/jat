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

    # If the registered plugin already exists, use it. Otherwise, require
    # and return it. This raises a LoadError if such a plugin doesn't exist,
    # or a Jat::Error if it exists but it does not register itself
    # correctly.
    def self.find_plugin(name)
      return name if name.is_a?(Module)
      require "jat/plugins/#{name}/#{name}" unless @plugins.key?(name)

      @plugins[name] || raise(Error, "plugin #{name} did not register itself correctly in Jat::Plugins")
    end
  end
end
