# frozen_string_literal: true

#
# Parent class for your serializers
#
class Jat
  #
  # A generic exception used by Jat.
  #
  class Error < StandardError; end

  # @return [Hash] frozen hash
  FROZEN_EMPTY_HASH = {}.freeze

  # @return [Array] frozen array
  FROZEN_EMPTY_ARRAY = [].freeze
end

require_relative "jat/anonymous_class"
require_relative "jat/attribute"
require_relative "jat/config"
require_relative "jat/plugins"

class Jat
  @config = Config.new({plugins: []})

  #
  # Jat serializers core class methods
  #
  module ClassMethods
    # @return [Config] current serializer config
    attr_reader :config

    #
    # This method called automatically when current serializer is inherited.
    # Copies config and attributes into inherited subclass
    #
    # @param subclass [Jat] inherited class
    #
    # @return [void]
    #
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
      attributes.each_value do |attr|
        subclass.attribute(attr.name, **attr.opts, &attr.block)
      end

      super
    end

    #
    # Enables plugin for current serializer
    #
    # @param name [Symbol, Module] Plugin name or plugin module itself
    # @param opts [Hash>] Any hash of options that enabled plugin can accept
    #
    # @return [Module] Loaded plugin
    #
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

    #
    # Checks plugin is used
    #
    # @param name [Symbol, Module] Plugin name or plugin module itself
    #
    # @return [Boolean]
    #
    def plugin_used?(name)
      plugin_name =
        case name
        when Module then name.respond_to?(:plugin_name) ? name.plugin_name : name
        else name
        end

      config[:plugins].include?(plugin_name)
    end

    #
    # Serializes object
    #
    # @param object [Object] Serialized object (any type)
    # @param context [Hash] Serialization context
    #
    # @return [Hash] Serialization result
    #
    def to_h(object, context = nil)
      new(context || {}).to_h(object)
    end

    #
    # Lists attributes
    #
    # @return [Hash<Symbol, Jat::Attribute>] attributes list
    #
    def attributes
      @attributes ||= {}
    end

    #
    # Adds attribute
    #
    # @param name [Symbol] Attribute name. Attribute value will be found by executing `object.<name>`
    # @param opts [Hash] Options to serialize attribute
    # @option opts [Symbol] :key Attribute value will be found by executing `object.<key>`
    # @option opts [Boolean] :expose Specifies if current attribute is exposed or not
    # @option opts [Symbol, #call] :type For `types` plugin only. Casts attribute value to provided type
    # @option opts [Symbol, Hash, Array] :preload For `activerecord` plugin only. Automatically preloads provided associations to serialized objects
    #
    # @param block [Proc] Accepts optional object and context. Stores block to get attribute value when serializing object
    #
    # @return [Jat::Attribute] Added attribute
    #
    def attribute(name, **opts, &block)
      new_attr = self::Attribute.new(name: name, opts: opts, block: block)
      attributes[new_attr.serialized_name] = new_attr
    end

    #
    # Adds relationship attribute
    #
    # @param name [Symbol] Attribute name. Attribute value will be found by executing `object.<name>`
    # @param serializer [Jat, Proc] Specifies nested serializer for relationship
    # @param opts [Hash] Options for attribute serialization
    # @option opts [Symbol] :key Attribute value will be found by executing `object.<key>`
    # @option opts [Boolean] :expose Specifies if current attribute is exposed or not
    # @option opts [Boolean] :many Tells explicitly that value is some kind of list
    # @option opts [Symbol, Hash, Array] :preload For `activerecord` plugin only. Automatically preloads provided associations to serialized objects
    #
    # @param block [Proc] Accepts optional object and context. Stores block to get attribute value when serializing object
    #
    # @return [Jat::Attribute] Added attribute
    #
    def relationship(name, serializer:, **opts, &block)
      attribute(name, serializer: serializer, **opts, &block)
    end
  end

  #
  # Jat serializers core instance methods
  #
  module InstanceMethods
    attr_reader :context

    #
    # Instantiates new Jat class. It will be more effective to call this manually if context is constant.
    #
    # @param context [Hash] Serialization context
    #
    def initialize(context = {})
      @context = context
    end

    #
    # Serializes provided object to hash
    #
    # @param _object [Object] Serialized object
    #
    # @return [Hash] Serialization result
    #
    def to_h(_object)
      raise Error, "Method #to_h must be implemented by plugin"
    end
  end

  extend ClassMethods
  include InstanceMethods
end
