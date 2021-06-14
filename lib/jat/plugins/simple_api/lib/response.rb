# frozen_string_literal: true

# Serializes to JSON-API format
class Jat
  module Plugins
    module SimpleApi
      class Response
        attr_reader :jat, :jat_class, :object, :context

        def initialize(jat)
          @jat = jat
          @jat_class = jat.class
          @object = jat.object
          @context = jat.context
        end

        def response
          # Add main response
          result = many? ? many(object) : one(object)
          result = {root_key => result} if root_key
          result ||= {}

          # Add metadata to response
          # We can add metadata to empty response, or to top-level namespace
          # We should not mix metadata with object attributes
          metadata.tap do |meta|
            next if meta.empty?
            raise Error, "Response must have a root key to add metadata" if !result.empty? && !root_key
            result[meta_key] = meta
          end

          result
        end

        private

        def metadata
          result = context[:meta] || {}

          config_meta = jat_class.config[:meta]
          return result unless config_meta

          config_meta.each_with_object(result) do |(key, value), res|
            next if res.key?(key) # do not overwrite manually added meta

            value = value.call(object, context) if value.respond_to?(:call)
            res[key] = value unless value.nil?
          end
        end

        def many(objects)
          objects.map { |obj| one(obj) }
        end

        def one(obj)
          ResponseData.new(jat_class, obj, context, jat.traversal_map).data
        end

        def many?
          @is_many ||= begin
            many = context[:many]
            many.nil? ? object.is_a?(Enumerable) : many
          end
        end

        # We can provide nil or false to remove root
        def root_key
          @root_key ||=
            if context.key?(:root)
              context[:root]
            else
              (many? ? jat_class.root_for_many : jat_class.root_for_one) || jat_class.root
            end
        end

        def meta_key
          context[:meta_key] || jat_class.meta_key
        end
      end

      class ResponseData
        attr_reader :jat_class, :object, :context, :map, :presenter

        def initialize(jat_class, object, context, map)
          @jat_class = jat_class
          @object = object
          @context = context
          @map = map
          @presenter = jat_class::Presenter.new(object, context)
        end

        def data
          return unless object

          result = {}

          map.each do |key, inner_keys|
            attribute = jat_class.attributes.fetch(key)
            value = presenter.public_send(attribute.original_name)

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
