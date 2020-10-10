# frozen_string_literal: true

class Jat
  class Opts
    EXPOSED = {
      all: :exposed_all,
      none: :exposed_none,
      default: :exposed_default
    }.freeze

    attr_reader :name

    def initialize(current_serializer, name, opts, original_block)
      @current_serializer = current_serializer
      @name = name.to_sym
      @opts = opts.freeze
      @original_block = original_block
    end

    def key
      @key ||= opts.key?(:key) ? opts[:key].to_sym : name
    end

    # We should not memorize this method as it depends on current serializer options
    def delegate?
      opts.fetch(:delegate, current_serializer.options[:delegate])
    end

    # We should not memorize this method as it depends on current serializer options
    def exposed?
      exposed_method = EXPOSED.fetch(current_serializer.options[:exposed])
      __send__(exposed_method)
    end

    def many?
      return @many if defined?(@many)

      @many = opts.fetch(:many, false)
    end

    def relation?
      return @relation if defined?(@relation)

      @relation = opts.key?(:serializer)
    end

    def serializer
      return @serializer if defined?(@serializer)

      @serializer = relation? ? opts[:serializer].call : nil
    end

    def includes
      return @includes if defined?(@includes)

      @includes = begin
        inc = relation? ? opts.fetch(:includes, key) : opts[:includes]
        Services::IncludesToHash.(inc) if inc
      end
    end

    # We should not memorize this method as it depends on current serializer options
    def block
      return if !original_block && !delegate?

      original_block ? transform_original_block : delegate_block
    end

    private

    attr_reader :current_serializer, :opts, :original_block

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
      -> (obj, _params) { obj.public_send(delegate_field) }
    end
  end
end
