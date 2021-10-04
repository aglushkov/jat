# frozen_string_literal: true

# Serializes to JSON-API format
class Jat
  module Plugins
    module JsonApi
      class Response
        EMPTY = {}.freeze

        attr_reader :jat, :jat_class, :object, :context

        def initialize(jat)
          @jat = jat
          @jat_class = jat.class
          @object = jat.object
          @context = jat.context
        end

        def response
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
          data = many?(object, context) ? many(object, includes) : one(object, includes)
          [data, includes]
        end

        def many(objs, includes)
          objs.map { |obj| one(obj, includes) }
        end

        def one(obj, includes)
          ResponseData.new(jat_class, obj, context, full_map, includes).data
        end

        def many?(data, context)
          many = context[:many]
          many.nil? ? data.is_a?(Enumerable) : many
        end

        def full_map
          @full_map ||= jat.traversal_map.current
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

      class ResponseData
        EMPTY_HASH = {}.freeze
        EMPTY_ARRAY = [].freeze
        attr_reader :jat_class, :object, :context, :full_map, :map, :includes

        def initialize(jat_class, object, context, full_map, includes)
          @jat_class = jat_class
          @object = object
          @context = context
          @includes = includes
          @full_map = full_map
          @map = full_map.fetch(jat_class.type)
        end

        def data
          return unless object

          attributes = get_attributes
          relationships = get_relationships
          links = get_links
          meta = get_meta

          result = uid
          result[:attributes] = attributes if attributes
          result[:relationships] = relationships if relationships
          result[:links] = links if links.any?
          result[:meta] = meta if meta.any?
          result
        end

        def uid
          {type: jat_class.type, id: jat_class.attributes[:id].block.call(object, context)}
        end

        private

        def get_attributes
          attributes_names = map[:attributes]
          return if attributes_names.empty?

          attributes_names.each_with_object({}) do |name, attrs|
            attribute = jat_class.attributes[name]
            attrs[name] = attribute.block.call(object, context)
          end
        end

        def get_relationships
          relationships_names = map[:relationships]
          return if relationships_names.empty?

          relationships_names.each_with_object({}) do |name, rels|
            rel_attribute = jat_class.attributes[name]
            rel_object = rel_attribute.block.call(object, context)

            rel_serializer = rel_attribute.serializer.call
            rel_links = get_relationship_links(rel_serializer, rel_object)
            rel_meta = get_relationship_meta(rel_serializer, rel_object)
            rel_data =
              if many?(rel_attribute, rel_object)
                many_relationships_data(rel_serializer, rel_object)
              else
                one_relationship_data(rel_serializer, rel_object)
              end

            result = {}
            result[:data] = rel_data
            result[:links] = rel_links if rel_links.any?
            result[:meta] = rel_meta if rel_meta.any?
            rels[name] = result
          end
        end

        def many_relationships_data(rel_serializer, rel_objects)
          return EMPTY_ARRAY if rel_objects.empty?

          rel_objects.map { |rel_object| add_relationship_data(rel_serializer, rel_object) }
        end

        def one_relationship_data(rel_serializer, rel_object)
          return unless rel_object

          add_relationship_data(rel_serializer, rel_object)
        end

        def add_relationship_data(rel_serializer, rel_object)
          rel_response_data = self.class.new(rel_serializer, rel_object, context, full_map, includes)
          rel_uid = rel_response_data.uid
          includes[rel_uid] ||= rel_response_data.data
          rel_uid
        end

        def many?(attribute, object)
          is_many = attribute.many?

          # handle boolean
          return is_many if (is_many == true) || (is_many == false)

          # handle nil
          object.is_a?(Enumerable)
        end

        def get_links
          jat_class
            .object_links
            .transform_values { |attr| attr.block.call(object, context) }
            .tap(&:compact!)
        end

        def get_meta
          jat_class
            .added_object_meta
            .transform_values { |attr| attr.block.call(object, context) }
            .tap(&:compact!)
        end

        def get_relationship_links(rel_serializer, rel_object)
          links = rel_serializer.relationship_links
          return EMPTY_HASH unless links

          context[:parent_object] = object

          links
            .transform_values { |attr| attr.block.call(rel_object, context) }
            .tap(&:compact!)
            .tap { context.delete(:parent_object) }
        end

        def get_relationship_meta(rel_serializer, rel_object)
          meta = rel_serializer.added_relationship_meta
          return EMPTY_HASH unless meta

          context[:parent_object] = object

          meta
            .transform_values { |attr| attr.block.call(rel_object, context) }
            .tap(&:compact!)
            .tap { context.delete(:parent_object) }
        end
      end
    end
  end
end
