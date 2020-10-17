# frozen_string_literal: true

require 'jat/response_data'

# Serializes to JSON-API format
class Jat
  class Response
    attr_reader :serializer, :object, :opts

    def initialize(serializer, object, opts)
      @serializer = serializer
      @object = object
      @opts = opts
    end

    def to_h
      includes = {}
      data = opts[:many] ? many(includes) : one(includes)
      response(data, includes, opts[:meta])
    end

    private

    def response(data, includes, meta)
      result = {}
      result[:data] = data if data
      result[:included] = includes.values unless includes == {}
      result[:meta] = meta if meta
      result
    end

    def many(includes)
      object.map { |obj| ResponseData.new(serializer, obj, includes).data }
    end

    def one(includes)
      ResponseData.new(serializer, object, includes).data
    end
  end
end
