# frozen_string_literal: true

require_relative "jat/attribute"
require_relative "jat/config"
require_relative "jat/plugins"

# Main namespace
class Jat
  FROZEN_EMPTY_HASH = {}.freeze
  FROZEN_EMPTY_ARRAY = [].freeze

  # A generic exception used by Jat.
  class Error < StandardError; end

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

      # Before load usually used to check plugin can be attached or to load additional plugins
      plugin.before_load(self, **opts) if plugin.respond_to?(:before_load)

      # Usually used to include/extend plugin modules
      plugin.load(self, **opts) if plugin.respond_to?(:load)

      # Store attached plugins, so we can check them later
      config[:plugins] << plugin

      # Set some config options for current plugin or load additional plugins
      plugin.after_load(self, **opts) if plugin.respond_to?(:after_load)

      plugin
    end

    def plugin_used?(name)
      plugin = Plugins.find_plugin(name)
      config[:plugins].include?(plugin)
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
