# frozen_string_literal: true

class Jat
  # :reek:TooManyInstanceVariables
  class Attribute
    attr_reader :opts,
                :block,
                :delegate,
                :exposed,
                :preloads,
                :preloads_path,
                :key,
                :many,
                :name,
                :original_name,
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

    # rubocop:disable Metrics/AbcSize
    # :reek:TooManyStatements
    # Some attributes options depends on serializer options, so when we change
    # options, we need to update stored attributes, thats why we need this
    # refresh method.
    def refresh
      @block = opts.block
      @delegate = opts.delegate?
      @exposed = opts.exposed?
      @preloads, @preloads_path = opts.preloads_with_path
      @key = opts.key
      @many = opts.many?
      @name = opts.name
      @original_name = opts.original_name
      @relation = opts.relation?
      @serializer = opts.serializer
    end
    # rubocop:enable Metrics/AbcSize

    def copy_to(subclass)
      opts_copy = opts.copy_to(subclass)
      self.class.new(opts_copy)
    end
  end
end
