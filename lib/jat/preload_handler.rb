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
        return objects if skip_preload?(objects, serializer)

        preloads = Preloads.new(serializer._full_map).for(serializer.class)
        return objects if preloads.empty?

        preload(objects, preloads)
      end

      private

      def preload(objects, preloads)
        preload_handler = HANDLERS.find { |handler| handler.fit?(objects) }
        raise Error, "Can't preload #{preloads.inspect} to #{objects.inspect}" unless preload_handler

        preload_handler.preload(objects, preloads)
      end

      def skip_preload?(objects, serializer)
        !objects ||
          !serializer.class.config.auto_preload ||
          (objects.is_a?(Array) && objects.empty?)
      end
    end
  end
end
