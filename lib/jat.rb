# frozen_string_literal: true

require 'jat/plugins'

# Main namespace
class Jat
  @opts = { delegate: true }

  # A generic exception used by Jat.
  class Error < StandardError
  end

  module ClassMethods
    attr_reader :opts

    def keys
      @keys ||= {}
    end

    def inherited(subclass)
      subclass.instance_variable_set(:@opts, deep_dup(opts))
    end

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

    private

    def add_key(key, key_opts, &block)
      key = key.to_sym
      keys[key] = key_opts

      add_method(key, key_opts, block)

      opts
    end

    def add_method(key, key_opts, block)
      if block
        add_block_method(key, block)
      else
        delegate = key_opts.fetch(:delegate, opts[:delegate])
        add_delegate_method(key, delegate) if delegate
      end
    end

    def add_block_method(key, block)
      # Warning-free method redefinition
      remove_method(key) if method_defined?(key)

      case block.parameters.count
      when 2 then define_method(key, &block)
      when 1 then define_method(key) { |obj, _params| block.(obj) }
      else raise JAT::Error, 'Invalid block arguments number, must be 1 (object) or 2 (object, params)'
      end
    end

    def add_delegate_method(key, delegate)
      delegate_field = key if delegate == true
      block  = ->(obj, _params) { obj.public_send(delegate_field) }

      add_block_method(key, block)
    end

    def deep_dup(hash)
      duplicate_hash = hash.dup

      if duplicate_hash.is_a?(Hash)
        duplicate_hash.each do |key, value|
          duplicate_hash[key] = deep_dup(value) if value.is_a?(Enumerable)
        end
      end

      duplicate_hash
    end
  end

  extend ClassMethods

  plugin :json_api
end
