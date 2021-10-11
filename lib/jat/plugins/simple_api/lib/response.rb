# frozen_string_literal: true

# Serializes to JSON-API format
class Jat
  module Plugins
    module SimpleApi
      class Response
        module ClassMethods
          # Returns the Jat class that this Response class is namespaced under.
          attr_accessor :jat_class

          # Since Response is anonymously subclassed when Jat is subclassed,
          # and then assigned to a constant of the Jat subclass, make inspect
          # reflect the likely name for the class.
          def inspect
            "#{jat_class.inspect}::Response"
          end

          def call(object, context)
            new(object, context).to_h
          end
        end

        module InstanceMethods
          attr_reader :object, :context, :jat_class

          def initialize(object, context)
            @object = object
            @context = context
            @jat_class = self.class.jat_class
          end

          def to_h
            # Add main response
            is_many = many?
            root = root_key(is_many)

            result = is_many ? many(object) : one(object)
            result = {root => result} if root
            result ||= {}

            # Add metadata to response
            # We can add metadata to empty response, or to top-level namespace
            # We should not mix metadata with object attributes
            metadata.tap do |meta|
              next if meta.empty?
              raise Error, "Response must have a root key to add metadata" if !result.empty? && !root
              result[meta_key] = meta
            end

            result
          end

          private

          def many(objects)
            objects.map { |obj| one(obj) }
          end

          def one(obj)
            map = jat_class.map(context)
            jat_class::ResponsePiece.to_h(obj, context, map)
          end

          def many?
            many = context[:many]
            many.nil? ? object.is_a?(Enumerable) : many
          end

          # We can provide nil or false to remove root
          def root_key(is_many)
            if context.key?(:root)
              root = context[:root]
              root ? root.to_sym : root
            else
              config = jat_class.config
              is_many ? config[:root_many] : config[:root_one]
            end
          end

          def meta_key
            context[:meta_key]&.to_sym || jat_class.config[:meta_key]
          end

          def metadata
            data = context_metadata
            data.transform_keys! { |key| CamelLowerTransformation.call(key) } if jat_class.config[:camel_lower]

            meta = jat_class.added_meta
            return data if meta.empty?

            meta.each_value do |attribute|
              name = attribute.name
              next if data.key?(name)

              value = attribute.block.call(object, context)
              data[name] = value if value
            end

            data
          end

          def context_metadata
            context[:meta]&.transform_keys(&:to_sym) || {}
          end
        end

        extend ClassMethods
        include InstanceMethods
      end
    end
  end
end
