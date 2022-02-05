# frozen_string_literal: true

class Jat
  module Plugins
    module JsonApi
      class Response
        module ClassMethods
          def call(object, context)
            new(object, context).to_h
          end
        end

        module InstanceMethods
          attr_reader :serializer_class, :object, :context

          def initialize(object, context)
            @object = object
            @context = context
            @serializer_class = self.class.serializer_class
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
            map = serializer_class::Map.call(context)
            data = many?(object, context) ? many(object, includes, map) : one(object, includes, map)
            [data, includes]
          end

          def many(objects, includes, map)
            objects.map { |object| one(object, includes, map) }
          end

          def one(object, includes, map)
            serializer_class::ResponsePiece.call(object, context, map, includes)
          end

          def many?(data, context)
            many = context[:many]
            many.nil? ? data.is_a?(Enumerable) : many
          end

          def jsonapi_data
            combine(serializer_class.jsonapi_data, context_jsonapi)
          end

          def document_links
            combine(serializer_class.document_links, context_links)
          end

          def document_meta
            combine(serializer_class.added_document_meta, context_meta)
          end

          def combine(attributes, context_data)
            return context_data if attributes.empty?

            data = context_data

            attributes.each do |name, attribute|
              next if data.key?(name)

              value = attribute.value(object, context)

              unless value.nil?
                data = data.dup if data.equal?(FROZEN_EMPTY_HASH)
                data[name] = value
              end
            end

            data
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

        extend Jat::Helpers::SerializerClassHelper
        extend ClassMethods
        include InstanceMethods
      end
    end
  end
end
