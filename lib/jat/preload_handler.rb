# frozen_string_literal: true

require 'jat/preload_handler/active_record_array'
require 'jat/preload_handler/active_record_object'
require 'jat/preload_handler/active_record_relation'

class Jat
  class PreloadHandler
    class << self
      def call(objects, serializer)
        return objects if !objects || !serializer.class.config.auto_preload
        return objects if objects.is_a?(Array) && objects.empty?

        includes = serializer._includes
        return objects if includes.empty?

        preload(objects, includes)
      end

      private

      def preload(objects, includes)
        preload_handler = handlers.find { |handler| handler.fit?(objects) }

        unless preload_handler
          raise Error, "Don't know how to preload nested data to class: #{objects.class}, data: #{objects.inspect}"
        end

        preload_handler.preload(objects, includes)
      end

      def handlers
        @handlers ||=
          if defined?(ActiveRecord)
            [
              ActiveRecordRelation,
              ActiveRecordObject,
              ActiveRecordArray
            ]
          else
            []
          end
      end
    end
  end
end
