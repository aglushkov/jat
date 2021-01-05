# frozen_string_literal: true

require 'jat/attribute_params'

class Jat
  # :reek:TooManyInstanceVariables
  #
  # Stores custom options provided by user to serialize specific field
  class Attribute
    attr_reader :jat_class,
                :params,
                :block,
                :exposed,
                :preloads,
                :preloads_path,
                :key,
                :many,
                :name,
                :original_name,
                :relation,
                :serializer

    alias exposed? exposed
    alias many? many
    alias relation? relation

    def initialize(jat_class, params)
      @params = params
      @jat_class = jat_class

      refresh
    end

    # :reek:TooManyStatements
    # Some attributes options depend on jat_class options, so when we change
    # options, we need to update already stored attributes, thats why we need
    # this refresh method.
    def refresh
      opts = AttributeParams.new(jat_class, params)

      @block = opts.block
      @exposed = opts.exposed?
      @preloads, @preloads_path = opts.preloads_with_path
      @key = opts.key
      @many = opts.many?
      @name = opts.name
      @original_name = opts.original_name
      @relation = opts.relation?
      @serializer = opts.serializer
    end
  end
end
