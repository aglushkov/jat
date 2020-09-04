# frozen_string_literal: true

# Serializes to JSON-API format
class Jat
  module Plugins
    module JSON_API
      class Serializer
        class << self
          def call(object, serializer_class, many: false, meta: {}, params: {})
            includes = {}
            data = data(object, serializer_class, many, includes, params)

            response = {}
            response[:data] = data if data
            response[:included] = includes.values unless includes.empty?

            # TODO: Validate meta is a hash as required in specs
            response[:meta] = meta if meta && !meta.empty?
            response
          end

          private

          def data(object, serializer_class, many, includes, params)
            serializer = serializer_class.new(params)
            serializer.(object, includes, many)
          end
        end
      end
    end
  end
end
