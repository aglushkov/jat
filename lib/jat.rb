# frozen_string_literal: true

require_relative "jat/attribute"
require_relative "jat/presenter"
require_relative "jat/config"
require_relative "jat/plugins"

# Main namespace
class Jat
  # A generic exception used by Jat.
  class Error < StandardError; end

  @config = Config.new

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

      # Initialize object presenter
      presenter_class = Class.new(self::Presenter)
      presenter_class.jat_class = subclass
      subclass.const_set(:Presenter, presenter_class)

      # Assign same attributes
      attributes.each_value do |attribute|
        params = attribute.params
        subclass.attribute(params[:name], **params[:opts], &params[:block])
      end

      super
    end

    def plugin(plugin, **opts)
      if !plugin.is_a?(Symbol) && !plugin.is_a?(Module)
        raise Error, "Plugin class must be a Symbol or a Module, #{plugin.inspect} given"
      end

      plugin = Plugins.load_plugin(plugin) if plugin.is_a?(Symbol)

      Plugins.before_load(plugin, self, **opts)

      include(plugin::InstanceMethods) if defined?(plugin::InstanceMethods)
      extend(plugin::ClassMethods) if defined?(plugin::ClassMethods)

      self::Attribute.include plugin::AttributeMethods if defined?(plugin::AttributeMethods)
      self::Attribute.extend plugin::AttributeClassMethods if defined?(plugin::AttributeClassMethods)

      self::Config.include plugin::ConfigMethods if defined?(plugin::ConfigMethods)
      self::Config.extend plugin::ConfigClassMethods if defined?(plugin::ConfigClassMethods)

      self::Presenter.include plugin::PresenterMethods if defined?(plugin::PresenterMethods)
      self::Presenter.extend plugin::PresenterClassMethods if defined?(plugin::PresenterClassMethods)

      Plugins.after_load(plugin, self, **opts)
      plugin
    end

    def call
      self
    end

    def to_h(object, context = nil)
      new(object, context || {}).to_h
    end

    def attributes
      @attributes ||= {}
    end

    def attribute(name, **opts, &block)
      new_attr = self::Attribute.new(name: name, opts: opts, block: block)
      attributes[new_attr.name] = new_attr
      self::Presenter.add_method(new_attr.original_name, new_attr.block)
      new_attr
    end
  end

  module InstanceMethods
    attr_reader :object, :context

    def initialize(object, context)
      @object = object
      @context = context
    end

    def to_h
      raise Error, "Method #to_h must be implemented by plugin"
    end

    def config
      self.class.config
    end
  end

  extend ClassMethods
  include InstanceMethods
end
