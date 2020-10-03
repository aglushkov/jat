# frozen_string_literal: true

require 'jat/utils/includes_to_hash'
require 'jat/plugins'
require 'jat/check_key'

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

      CheckKey.extend(plugin::CheckKey::ClassMethods) if defined?(plugin::CheckKey::ClassMethods)
      # Plugins.configure(plugin, self, *args, **kwargs, &block)
      plugin
    end

    def key(name, **opts, &block)
      CheckKey.(name: name, opts: opts, block: block)

      add_key(name, opts, block)
    end

    private

    # All opts must have symbol keys
    def add_key(name, opts, block)
      name = name.to_sym
      generate_opts_key(name, opts)
      generate_opts_include(opts)
      keys[name] = opts

      add_method(name, opts, block)

      [name, opts, block]
    end

    def add_method(name, opts, block)
      if block
        add_block_method(name, block)
      else
        delegate = opts.fetch(:delegate, options[:delegate])
        add_delegate_method(name, opts) if delegate
      end
    end

    def add_block_method(name, block)
      # Warning-free method redefinition
      remove_method(name) if method_defined?(name)

      case block.parameters.count
      when 2 then define_method(name, &block)
      when 1 then define_method(name) { |obj, _params| block.(obj) }
      end
    end

    def add_delegate_method(name, opts)
      delegate_field = opts[:key]
      block  = ->(obj, _params) { obj.public_send(delegate_field) }

      add_block_method(name, block)
    end

    def generate_opts_key(name, opts)
      opts[:key] = opts.key?(:key) ? opts[:key].to_sym : name
    end

    def generate_opts_include(opts)
      includes = opts[:serializer] ? opts.fetch(:includes, opts[:key]) : opts[:includes]
      opts[:includes] = Utils::IncludesToHash.(includes) if includes
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
