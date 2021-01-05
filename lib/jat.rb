# frozen_string_literal: true

require 'jat/attributes'
require 'jat/attribute_params/validate'
require 'jat/presenter'
require 'jat/config'
require 'jat/error'
require 'jat/map'
require 'jat/map/construct'
require 'jat/preloads'
require 'jat/preload_handler'
require 'jat/response'
require 'jat/utils/preloads_to_hash'

# Main namespace
class Jat
  module ClassMethods
    # :reek:TooManyStatements
    # :reek:FeatureEnvy
    def inherited(subclass)
      # Initialize empty presenter
      presenter_class = Class.new(Presenter)
      presenter_class.jat_class = subclass
      subclass.const_set(:Presenter, presenter_class)

      # Add DSL methods
      subclass.extend DSLClassMethods
      subclass.include DSLInstanceMethods

      # Copy config
      config.each { |name, value| subclass.config.public_send("#{name}=", value) }

      # Copy attributes
      attributes.each_value { |attribute| subclass.attributes.add(attribute.params) }

      subclass.type(@type) if defined?(@type)

      super
    end

    def config
      @config ||= Config.new(self)
    end

    def attributes
      @attributes ||= Attributes.new(self)
    end

    # Used to validate provided params (fields, include)
    def full_map
      @full_map ||= Map::Construct.new(self, :all).to_h
    end

    # Used to serialize final response
    def exposed_map
      @exposed_map ||= Map::Construct.new(self, :exposed).to_h
    end

    def clear
      @full_map = nil
      @exposed_map = nil
    end

    def refresh
      attributes.refresh
      clear
    end
  end

  module DSLClassMethods
    def call
      self
    end

    def to_h(object, context = {})
      new.to_h(object, context)
    end

    def to_str(object, context = {})
      new.to_str(object, context)
    end

    def type(new_type = nil)
      return (defined?(@type) && @type) || raise(Error, "#{self} has no defined type") unless new_type

      new_type = new_type.to_sym
      @type = new_type
    end

    def attribute(name, **opts, &block)
      add_attribute(name: name, opts: opts, block: block)
    end

    def relationship(name, serializer:, **opts, &block)
      opts[:serializer] = serializer
      add_attribute(name: name, opts: opts, block: block)
    end

    private

    def add_attribute(params)
      AttributeParams::Validate.(params)
      attribute = attributes.add(params)
      clear

      attribute
    end
  end

  # :reek:ModuleInitialize
  module DSLInstanceMethods
    attr_reader :_context

    def initialize(context = {}, full_map = nil)
      @_context = context.dup
      @_full_map = full_map
    end

    def to_h(object, context = {})
      _reinitialize(context)
      Response.new(self, object).to_h
    end

    def to_str(object, context = {})
      _reinitialize(context)
      Response.new(self, object).to_str
    end

    def _full_map
      @_full_map ||= begin
        params = _context[:params]
        fields = params && (params[:fields] || params['fields'])
        includes = params && (params[:include] || params['include'])
        Map.(self.class, fields, includes)
      end
    end

    def _map
      @_map ||= _full_map.fetch(self.class.type)
    end

    private

    def _reinitialize(context)
      new_params = context[:params]
      old_params = _context[:params]

      # maps depend on params, so we should clear them when params changed
      if new_params != old_params
        @_full_map = nil
        @_map = nil
      end

      @_context = _context.merge!(context)
    end
  end

  extend ClassMethods
end
