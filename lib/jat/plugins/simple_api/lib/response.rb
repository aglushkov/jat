# frozen_string_literal: true

# Serializes to JSON-API format
class Jat
  module Plugins
    module SimpleApi
      class Response
        module InstanceMethods
          attr_reader :jat, :jat_class, :object, :context, :config

          def initialize(jat)
            @jat = jat
            @jat_class = jat.class
            @object = jat.object
            @context = jat.context
            @config = jat_class.config
          end

          def response
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
            ResponseData.new(jat_class, obj, context, jat.traversal_map).data
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
              is_many ? config[:root_many] : config[:root_one]
            end
          end

          def meta_key
            context[:meta_key]&.to_sym || config[:meta_key]
          end

          def metadata
            data = context_metadata
            data.transform_keys! { |key| CamelLowerTransformation.call(key) } if jat_class.config[:camel_lower]

            meta = jat_class.added_meta
            return data if meta.empty?

            meta.each_value do |attr|
              name = attr.name
              next if data.key?(name)

              value = attr.block.call(object, context)
              data[name] = value if value
            end

            data
          end

          def context_metadata
            context[:meta]&.transform_keys(&:to_sym) || {}
          end
        end

        include InstanceMethods
      end

      class ResponseData
        attr_reader :jat_class, :object, :context, :map, :presenter

        def initialize(jat_class, object, context, map)
          @jat_class = jat_class
          @object = object
          @context = context
          @map = map
        end

        def data
          return unless object

          result = {}

          map.each do |key, inner_keys|
            attribute = jat_class.attributes.fetch(key)
            value = attribute.block.call(object, context)

            result[key] =
              if attribute.relation?
                if many?(attribute, value)
                  value.map { |obj| response_data(attribute, obj, inner_keys) }
                else
                  response_data(attribute, value, inner_keys)
                end
              else
                value
              end
          end

          result
        end

        private

        def response_data(attribute, value, map)
          ResponseData.new(attribute.serializer.call, value, context, map).data
        end

        def many?(attribute, object)
          is_many = attribute.many?

          # handle boolean
          return is_many if (is_many == true) || (is_many == false)

          # handle nil
          object.is_a?(Enumerable)
        end
      end
    end
  end
end
