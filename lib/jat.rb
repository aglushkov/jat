# frozen_string_literal: true

require 'jat/plugins'

# Main namespace
class Jat

  # A generic exception used by Jat.
  class Error < StandardError
  end

  class << self
    # Load a new plugin into the current class. A plugin can be a module
    # which is used directly, or a symbol representing a registered plugin
    # which will be required and then loaded.
    #
    #     Jat.plugin MyPlugin
    #     Jat.plugin :my_plugin
    def plugin(plugin, *args, **kwargs, &block)
      plugin = Plugins.load_plugin(plugin) if plugin.is_a?(Symbol)
      Plugins.load_dependencies(plugin, self, *args, **kwargs, &block)
      self.include(plugin::InstanceMethods) if defined?(plugin::InstanceMethods)
      self.extend(plugin::ClassMethods) if defined?(plugin::ClassMethods)
      # Plugins.configure(plugin, self, *args, **kwargs, &block)
      plugin
    end
  end


  plugin :json_api
end
