# frozen_string_literal: true

# Serializes to JSON-API format
class Jat
  module Plugins
    module JsonApi
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
          attr_reader :jat_class, :object, :context

          def initialize(object, context)
            @object = object
            @context = context
            @jat_class = self.class.jat_class
          end

          def to_h
            data, includes = data_with_includes
            meta = document_meta
            links = document_links
            jsonapi = jsonapi_data

            result = {}
            result[:links] = links if links.any?
            result[:data] = data if data
            result[:included] = includes.values if includes.any?
            result[:meta] = meta if meta.any?
            result[:jsonapi] = jsonapi if jsonapi.any?
            result
          end

          private

          def data_with_includes
            includes = {}
            map = jat_class::Map.call(context)
            data = many?(object, context) ? many(object, includes, map) : one(object, includes, map)
            [data, includes]
          end

          def many(objects, includes, map)
            objects.map { |object| one(object, includes, map) }
          end

          def one(object, includes, map)
            jat_class::ResponsePiece.call(object, context, map, includes)
          end

          def many?(data, context)
            many = context[:many]
            many.nil? ? data.is_a?(Enumerable) : many
          end

          def jsonapi_data
            combine(jat_class.jsonapi_data, context_jsonapi)
          end

          def document_links
            combine(jat_class.document_links, context_links)
          end

          def document_meta
            combine(jat_class.added_document_meta, context_meta)
          end

          def combine(attributes, context_data)
            return context_data if attributes.empty?

            data = context_data

            attributes.each do |name, attribute|
              next if data.key?(name)

              value = attribute_value(attribute)

              unless value.nil?
                data = data.dup if data.equal?(FROZEN_EMPTY_HASH)
                data[name] = value
              end
            end

            data
          end

          def attribute_value(attribute)
            attribute.block.call(object, context)
          end

          def context_jsonapi
            context_attr_transform(:jsonapi)
          end

          def context_links
            context_attr_transform(:links)
          end

          def context_meta
            context_attr_transform(:meta)
          end

          def context_attr_transform(key)
            context[key]&.transform_keys(&:to_sym) || FROZEN_EMPTY_HASH
          end
        end

        extend ClassMethods
        include InstanceMethods
      end
    end
  end
end
