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
            combine(jat_class.jsonapi_data, context[:jsonapi])
          end

          def document_links
            combine(jat_class.document_links, context[:links])
          end

          def document_meta
            combine(jat_class.added_document_meta, context[:meta])
          end

          def combine(attributes, attributes_context)
            data = attributes_context&.transform_keys(&:to_sym) || {}
            data.transform_keys! { |key| CamelLowerTransformation.call(key) } if jat_class.config[:camel_lower]

            return data if attributes.empty?

            attributes.each_value do |attr|
              name = attr.name
              next if data.key?(name)

              value = attr.block.call(object, context)
              data[name] = value unless value.nil?
            end

            data
          end
        end

        extend ClassMethods
        include InstanceMethods
      end
    end
  end
end
