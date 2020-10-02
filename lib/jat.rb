# frozen_string_literal: true

require 'jat/plugins'
require 'jat/validate'
require 'jat/includes_to_hash'

# Main namespace
class Jat
  @options = {
    delegate: true # false
  }

  # A generic exception used by Jat.
  class Error < StandardError
  end

  module ClassMethods
    attr_reader :options

    def keys
      @keys ||= {}
    end

    def inherited(subclass)
      subclass.instance_variable_set(:@options, deep_dup(options))
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

      Validate.extend(plugin::Validate::ClassMethods) if defined?(plugin::Validate::ClassMethods)
      # Plugins.configure(plugin, self, *args, **kwargs, &block)
      plugin
    end

    private

    # All opts must have symbol keys
    def add_key(key, **opts, &block)
      Validate.(key, opts, block)

      key = key.to_sym
      generate_opts_key(key, opts)
      generate_opts_include(opts)
      keys[key] = opts

      add_method(key, opts, block)

      [key, opts, block]
    end

    def add_method(key, opts, block)
      if block
        add_block_method(key, block)
      else
        delegate = opts.fetch(:delegate, options[:delegate])
        add_delegate_method(key, opts) if delegate
      end
    end

    def add_block_method(key, block)
      # Warning-free method redefinition
      remove_method(key) if method_defined?(key)

      case block.parameters.count
      when 2 then define_method(key, &block)
      when 1 then define_method(key) { |obj, _params| block.(obj) }
      end
    end

    def add_delegate_method(key, opts)
      delegate_field = opts[:key]
      block  = ->(obj, _params) { obj.public_send(delegate_field) }

      add_block_method(key, block)
    end

    def generate_opts_key(key, opts)
      opts[:key] = opts.key?(:key) ? opts[:key].to_sym : key
    end

    def generate_opts_include(opts)
      includes = opts.key?(:include) ? opts[:include] : begin
        opts[:key] if opts[:relationship]
      end

      opts[:include] = IncludesToHash.(includes) if includes
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
