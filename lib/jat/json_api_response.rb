# frozen_string_literal: true

require 'jat/response_data'

# Serializes to JSON-API format
class Jat
  class JsonApiResponse
    attr_reader :serializer, :object, :context

    def initialize(serializer, object)
      @serializer = serializer
      @object = object
      @context = serializer._context
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

    private

    def data_with_includes
      includes = {}
      data = many?(object, context) ? many(object, includes) : one(object, includes)
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

    def many(objs, includes)
      objs.map { |obj| one(obj, includes) }
    end

    def one(obj, includes)
      ResponseData.new(serializer, obj, includes).data
    end

    # :reek:NilCheck
    def many?(data, context)
      many = context[:many]
      many.nil? ? data.is_a?(Enumerable) : many
    end
  end
end