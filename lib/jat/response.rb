# frozen_string_literal: true

require 'jat/json_api_response'

# Prepares serialization and retuirns serialized response
class Jat
  class Response
    module InstanceMethods
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
        JsonApiResponse.new(serializer, object).response
      end

      def cached(format, &block)
        cache = context[:cache]
        return yield unless cache

        context[:format] = format
        cache.(object, context, &block) || yield
      end
    end

    module ClassMethods
      # Returns the Jat class that this Response class is namespaced under.
      # :reek:Attribute
      attr_accessor :jat_class

      # Since Response is anonymously subclassed when Jat is subclassed,
      # and then assigned to a constant of the Jat subclass, make inspect
      # reflect the likely name for the class.
      def inspect
        "#{jat_class.inspect}::Response"
      end
    end

    include InstanceMethods
    extend ClassMethods
  end
end
