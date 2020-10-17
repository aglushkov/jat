# frozen_string_literal: true

require 'jat/opts/check'

class Jat
  class Opts
    EXPOSED = {
      all: :exposed_all,
      none: :exposed_none,
      default: :exposed_default
    }.freeze

    attr_reader :current_serializer, :name, :opts, :original_block

    def initialize(current_serializer, params)
      Check.(params)

      @current_serializer = current_serializer
      @name = params.fetch(:name).to_sym
      @opts = params.fetch(:opts).freeze
      @original_block = params.fetch(:block)
    end

    def key
      opts.key?(:key) ? opts[:key].to_sym : name
    end

    def delegate?
      opts.fetch(:delegate, current_serializer.config.delegate)
    end

    def exposed?
      exposed_method = EXPOSED.fetch(current_serializer.config.exposed)
      __send__(exposed_method)
    end

    def many?
      opts.fetch(:many, false)
    end

    def relation?
      opts.key?(:serializer)
    end

    def serializer
      return unless relation?

      value = opts[:serializer]
      value.is_a?(Proc) ? proc_serializer(value) : value
    end

    def includes
      incl = relation? ? opts.fetch(:includes, key) : opts[:includes]
      Services::IncludesToHash.(incl) if incl
    end

    def block
      return if !original_block && !delegate?

      original_block ? transform_original_block : delegate_block
    end

    def copy_to(subclass)
      self.class.new(subclass, name: name, opts: opts, block: original_block)
    end

    private

    def exposed_all
      opts.fetch(:exposed, true)
    end

    def exposed_none
      opts.fetch(:exposed, false)
    end

    def exposed_default
      opts.fetch(:exposed, !relation?)
    end

    def transform_original_block
      block = original_block

      if block.parameters.count == 1
        ->(obj, _params) { block.(obj) }
      else # parameters.count == 2
        block
      end
    end

    def delegate_block
      delegate_field = key
      ->(obj, _params) { obj.public_send(delegate_field) }
    end

    def proc_serializer(value)
      value = value.()
      return value if value.is_a?(Class) && (value < Jat)

      raise Jat::Error, "Invalid serializer `#{value.inspect}`, must be a subclass of Jat"
    end
  end
end
