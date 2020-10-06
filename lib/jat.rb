# frozen_string_literal: true

require 'jat/check_key'
require 'jat/error'
require 'jat/includes'
require 'jat/map'
require 'jat/serialization_map'
require 'jat/serializer'
require 'jat/utils/includes_to_hash'

# Main namespace
class Jat
  @options = {
    delegate: true, # false
    exposed: :default, # all, none
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
      raise Error, "Key or block must be provided" if !key && !block

      block ||= proc { |obj| obj.public_send(key) }
      define_method(:id, &block)
    end

    def full_map
      @full_map ||= Map.(self, :all)
    end

    def exposed_map
      @exposed_map ||= Map.(self, :exposed)
    end

    def attribute(name, **opts, &block)
      opts = prepare_attributes_opts(opts)
      add_key(name, opts, block)
    end

    def relationship(name, serializer:, **opts, &block)
      opts = prepare_relationship_opts(serializer, opts)
      add_key(name, opts, block)
    end

    private

    def add_key(name, opts, block)
      CheckKey.(name: name, opts: opts, block: block)

      name = name.to_sym
      generate_opts_key(name, opts)
      generate_opts_include(opts)
      keys[name] = opts

      add_method(name, opts, block)

      [name, opts, block].tap { clear_maps }
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

      if block.parameters.count == 1
        define_method(name) { |obj, _params| block.(obj) }
      else # 2
        define_method(name, &block)
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

    def clear_maps
      @full_map = nil
      @exposed_map = nil
    end

    def prepare_attributes_opts(opts)
      exposed = options[:exposed] == :none ? false : true

      defaults = { exposed: exposed }
      defaults.merge!(opts)
    end

    def prepare_relationship_opts(serializer, opts)
      exposed = options[:exposed] == :all ? true : false

      defaults = { exposed: exposed, many: false }
      defaults.merge!(opts).merge!(serializer: serializer)
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
        SerializationMap.(self.class, fields, includes)
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
