# frozen_string_literal: true

require 'jat/attributes'

require 'jat/config'
require 'jat/error'
require 'jat/includes'
require 'jat/map'
require 'jat/opts'
require 'jat/serializer'
require 'jat/services/construct_map'
require 'jat/services/includes_to_hash'

# Main namespace
class Jat
  module ClassMethods
    def refresh
      attributes.refresh
      clear
    end

    def attributes
      @attributes ||= Attributes.new
    end

    def inherited(subclass)
      config.copy_to(subclass)
      attributes.copy_to(subclass)

      super
    end

    def type(new_type = nil)
      if new_type
        new_type = new_type.to_sym
        define_method(:type) { new_type }
        @type = new_type
      else
        raise Error, "#{self} has no defined type" unless @type

        @type
      end
    end

    def id(key: nil, &block)
      raise Error, "Key and block can't be provided together" if key && block
      raise Error, 'Key or block must be provided' if !key && !block

      block ||= proc { |obj| obj.public_send(key) }
      define_method(:id, &block)
    end

    def full_map
      @full_map ||= Services::ConstructMap.new(:all).for(self)
    end

    def exposed_map
      @exposed_map ||= Services::ConstructMap.new(:exposed).for(self)
    end

    def attribute(name, **opts, &block)
      add_attribute(name: name, opts: opts, block: block)
    end

    def relationship(name, serializer:, **opts, &block)
      opts[:serializer] = serializer
      add_attribute(name: name, opts: opts, block: block)
    end

    def config
      @config ||= Config.new(self)
    end

    def config=(config)
      @config = config
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

    def clear
      @full_map = nil
      @exposed_map = nil
    end
  end

  # Serializers DSL instance methods
  module InstanceMethods
    attr_reader :_params, :_full_map, :_map

    def initialize(params = nil, full_map = nil)
      @_params = params
      @_full_map = full_map || begin
        fields = params && (params[:fields] || params['fields'])
        includes = params && (params[:include] || params['include'])
        Map.(self.class, fields, includes)
      end
      @_map = @_full_map.fetch(type)
    end

    def to_h(obj, opts = {})
      Serializer.(obj, self, opts)
    end

    def id(obj)
      obj.id
    end

    def _includes
      Includes.new(_full_map).for(self.class)
    end
  end

  extend ClassMethods
  include InstanceMethods
end
