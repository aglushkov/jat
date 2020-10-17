# frozen_string_literal: true

require 'jat/attributes'
require 'jat/config'
require 'jat/error'
require 'jat/includes'
require 'jat/map'
require 'jat/map/construct'
require 'jat/opts'
require 'jat/response'
require 'jat/utils/includes_to_hash'

# Main namespace
class Jat
  module ClassMethods
    def inherited(subclass)
      subclass.extend DSLClassMethods
      subclass.include DSLInstanceMethods
      config.copy_to(subclass)
      attributes.copy_to(subclass)

      super
    end

    def config
      @config ||= Config.new(self)
    end

    def config=(config)
      @config = config
    end

    def attributes
      @attributes ||= Attributes.new
    end

    def full_map
      @full_map ||= Map::Construct.new(self, :all).to_h
    end

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
    def type(new_type = nil)
      return @type || raise(Error, "#{self} has no defined type") unless new_type

      new_type = new_type.to_sym
      define_method(:type) { new_type }
      @type = new_type
    end

    def id(key: nil, &block)
      raise Error, "Key and block can't be provided together" if key && block
      raise Error, 'Key or block must be provided' if !key && !block

      block ||= proc { |obj| obj.public_send(key) }
      define_method(:id, &block)
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
      opts = Opts.new(self, params)

      Attribute.new(opts).tap do |attribute|
        attributes << attribute
        add_method(attribute)
        clear
      end
    end

    def add_method(attribute)
      block = attribute.block
      return unless block

      name = attribute.name
      # Warning-free method redefinition
      remove_method(name) if method_defined?(name)
      define_method(name, &block)
    end
  end

  # :reek:ModuleInitialize
  module DSLInstanceMethods
    attr_reader :_params, :_map

    def initialize(params = nil, full_map = nil)
      @_params = params
      @_full_map = full_map
      @_map = _full_map.fetch(type)
    end

    def to_h(object, opts = {})
      Response.new(self, object, opts).to_h
    end

    def id(object)
      object.id
    end

    def _includes
      Includes.new(_full_map).for(self.class)
    end

    def _full_map
      @_full_map ||= begin
        fields = _params && (_params[:fields] || _params['fields'])
        includes = _params && (_params[:include] || _params['include'])
        Map.(self.class, fields, includes)
      end
    end

    def _copy_to(nested_serializer)
      nested_serializer.new(_params, _full_map)
    end
  end

  extend ClassMethods
end
