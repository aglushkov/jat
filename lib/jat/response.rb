# frozen_string_literal: true

require 'jat/response_data'

# Serializes to JSON-API format
class Jat
  class Response
    attr_reader :serializer, :object, :context

    def initialize(serializer, object)
      @serializer = serializer
      @object = object
      @context = serializer._context
    end

    def to_h
      cached(:hash) { build_response }
    end

    def to_str
      cached(:string) { serializer.class.config.to_str.(build_response) }
    end

    private

    def build_response
      @object = Jat::PreloadHandler.(object, serializer)
      response
    end

    # :reek:FeatureEnvy (refers to 'result' more than self)
    # :reek:TooManyStatements
    def response
      data, includes = data_with_includes
      meta = metadata

      result = {}
      result[:data] = data if data
      result[:included] = includes.values if includes.any?
      result[:meta] = meta if meta.any?
      result
    end

    def data_with_includes
      includes = {}
      data = many?(object, context) ? many(includes) : one(includes)
      [data, includes]
    end

    # :reek:ManualDispatch (respond_to?(:call)) # we can't do this other way
    # :reek:NilCheck (value.nil?) # we should check only nil. False is correct value.
    def metadata
      result = context[:meta] || {}

      serializer.class.config.meta.each_with_object(result) do |(key, value), res|
        next if res.key?(key) # do not overwrite manually added meta

        value = value.(object, context) if value.respond_to?(:call)
        res[key] = value unless value.nil?
      end
    end

    def many(includes)
      object.map { |obj| ResponseData.new(serializer, obj, includes).data }
    end

    def one(includes)
      ResponseData.new(serializer, object, includes).data
    end

    # :reek:NilCheck
    def many?(data, context)
      many = context[:many]
      many.nil? ? data.is_a?(Enumerable) : many
    end

    def cached(format, &block)
      cache = context[:cache]
      return yield unless cache

      context[:format] = format
      cache.(object, context, &block) || yield
    end
  end
end
