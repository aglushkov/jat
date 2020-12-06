# frozen_string_literal: true

require 'jat/preload_handler/active_record_array'
require 'jat/preload_handler/active_record_object'
require 'jat/preload_handler/active_record_relation'

class Jat
  class PreloadHandler
    HANDLERS = [
      ActiveRecordRelation,
      ActiveRecordObject,
      ActiveRecordArray
    ].freeze

    class << self
      def call(objects, serializer)
        return objects if !objects || !serializer.class.config.auto_preload
        return objects if objects.is_a?(Array) && objects.empty?

        preloads = serializer._preloads
        return objects if preloads.empty?

        preload(objects, preloads)
      end

      private

      def preload(objects, preloads)
        preload_handler = HANDLERS.find { |handler| handler.fit?(objects) }
        raise Error, "Can't preload #{preloads.inspect} to #{objects.inspect}" unless preload_handler

        preload_handler.preload(objects, preloads)
      end
    end
  end
end
