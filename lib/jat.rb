# frozen_string_literal: true

# Main namespace
class Jat
  # A generic exception used by Jat.
  class Error < StandardError; end

  FROZEN_EMPTY_HASH = {}.freeze
  FROZEN_EMPTY_ARRAY = [].freeze
end

require_relative "jat/attribute"
require_relative "jat/config"
require_relative "jat/plugins"

class Jat
  @config = Config.new({plugins: []})

  module ClassMethods
    attr_reader :config

    def inherited(subclass)
      # Initialize config
      config_class = Class.new(self::Config)
      config_class.jat_class = subclass
      subclass.const_set(:Config, config_class)
      subclass.instance_variable_set(:@config, subclass::Config.new(config.opts))

      # Initialize attribute class
      attribute_class = Class.new(self::Attribute)
      attribute_class.jat_class = subclass
      subclass.const_set(:Attribute, attribute_class)

      # Assign same attributes
      attributes.each_value do |attribute|
        params = attribute.params
        subclass.attribute(params[:name], **params[:opts], &params[:block])
      end

      super
    end

    def plugin(name, **opts)
      return if plugin_used?(name)

      plugin = Plugins.find_plugin(name)

      # We split loading of plugin to three methods - before_load, load, after_load:
      #
      # - **before_load** usually used to check requirements and to load additional plugins
      # - **load** usually used to include plugin modules
      # - **after_load** usually used to add config options
      plugin.before_load(self, **opts) if plugin.respond_to?(:before_load)
      plugin.load(self, **opts) if plugin.respond_to?(:load)
      plugin.after_load(self, **opts) if plugin.respond_to?(:after_load)

      # Store attached plugins, so we can check it is loaded later
      config[:plugins] << (plugin.respond_to?(:plugin_name) ? plugin.plugin_name : plugin)

      plugin
    end

    def plugin_used?(plugin)
      plugin_name =
        case plugin
        when Module then plugin.respond_to?(:plugin_name) ? plugin.plugin_name : plugin
        else plugin
        end

      config[:plugins].include?(plugin_name)
    end

    def call
      self
    end

    def to_h(object, context = nil)
      new(context || {}).to_h(object)
    end

    def attributes
      @attributes ||= {}
    end

    def attribute(name, **opts, &block)
      new_attr = self::Attribute.new(name: name, opts: opts, block: block)
      attributes[new_attr.name] = new_attr
    end

    def relationship(name, serializer:, **opts, &block)
      attribute(name, serializer: serializer, **opts, &block)
    end
  end

  module InstanceMethods
    attr_reader :context

    def initialize(context = {})
      @context = context
    end

    def to_h(_object)
      raise Error, "Method #to_h must be implemented by plugin"
    end

    def config
      self.class.config
    end
  end

  extend ClassMethods
  include InstanceMethods
end
