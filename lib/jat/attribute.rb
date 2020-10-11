# frozen_string_literal: true

class Jat
  class Attribute
    attr_reader :opts,
                :block,
                :delegate,
                :exposed,
                :includes,
                :key,
                :many,
                :relation,
                :serializer

    alias delegate? delegate
    alias exposed? exposed
    alias many? many
    alias relation? relation

    def initialize(opts)
      @opts = opts
      refresh
    end

    def refresh
      @block = opts.block
      @delegate = opts.delegate?
      @exposed = opts.exposed?
      @includes = opts.includes
      @key = opts.key
      @many = opts.many?
      @relation = opts.relation?
      @serializer = opts.serializer
    end
  end
end
