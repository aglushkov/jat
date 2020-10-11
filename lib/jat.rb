# frozen_string_literal: true

require 'jat/check_key'
require 'jat/error'
require 'jat/includes'
require 'jat/map'
require 'jat/opts'
require 'jat/serializer'
require 'jat/services/construct_map'
require 'jat/services/includes_to_hash'

# Main namespace
class Jat
  @options = {
    delegate: true, # false
    exposed: :default # all, none
  }

  module ClassMethods
    attr_reader :options

    def keys
      @keys ||= {}
    end

    def inherited(subclass)
      subclass.instance_variable_set(:@options, options.dup)
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
      add_key(name, opts, block)
    end

    def relationship(name, serializer:, **opts, &block)
      opts[:serializer] = serializer
      add_key(name, opts, block)
    end

    private

    def add_key(name, opts, block)
      CheckKey.(name: name, opts: opts, block: block)

      name = name.to_sym
      opts = Opts.new(self, name, opts, block)
      keys[name] = opts

      add_method(name, opts)
      clear
    end

    def add_method(name, opts)
      block = opts.block
      return unless block

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

    def to_h(obj, many: false, meta: nil)
      Serializer.(obj, self, many: many, meta: meta)
    end

    def id(obj)
      obj.id
    end

    def _includes
      Includes.(self.class, _full_map)
    end
  end

  extend ClassMethods
  include InstanceMethods
end
