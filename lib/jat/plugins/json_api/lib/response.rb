# frozen_string_literal: true

# Serializes to JSON-API format
class Jat
  module Plugins
    module JsonApi
      class Response
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
          data = context[:jsonapi]&.transform_keys(&:to_sym) || {}
          jsonapi_data = jat_class.jsonapi_data
          return data if jsonapi_data.empty?

          presenter = jat_class::JsonapiPresenter.new(object, context)
          jsonapi_data.each_key do |key|
            data[key] = presenter.public_send(key) unless data.key?(key)
          end
          data.compact!
          data
        end

        def document_links
          data = context[:links]&.transform_keys(&:to_sym) || {}
          document_links = jat_class.document_links
          return data if document_links.empty?

          presenter = jat_class::DocumentLinksPresenter.new(object, context)
          document_links.each_key do |key|
            data[key] = presenter.public_send(key) unless data.key?(key)
          end
          data.compact!
          data
        end

        def document_meta
          data = context[:meta]&.transform_keys(&:to_sym) || {}
          document_meta = jat_class.added_document_meta
          return data if document_meta.empty?

          presenter = jat_class::DocumentMetaPresenter.new(object, context)
          document_meta.each_key do |key|
            data[key] = presenter.public_send(key) unless data.key?(key)
          end
          data.compact!
          data
        end
      end

      class ResponseData
        attr_reader :jat_class, :object, :context, :full_map, :map, :includes, :presenter

        def initialize(jat_class, object, context, full_map, includes)
          @jat_class = jat_class
          @object = object
          @context = context
          @includes = includes
          @full_map = full_map
          @map = full_map.fetch(jat_class.type)
          @presenter = jat_class::Presenter.new(object, context)
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
          {type: jat_class.type, id: presenter.id}
        end

        private

        def get_attributes
          attributes_names = map[:attributes]
          return if attributes_names.empty?

          attributes_names.each_with_object({}) do |name, attrs|
            attribute = jat_class.attributes[name]
            attrs[name] = presenter.public_send(attribute.original_name)
          end
        end

        def get_relationships
          relationships_names = map[:relationships]
          return if relationships_names.empty?

          relationships_names.each_with_object({}) do |name, rels|
            rel_attribute = jat_class.attributes[name]
            rel_object = presenter.public_send(rel_attribute.original_name)

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
          return [] if rel_objects.empty?

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
          links = jat_class.object_links
          return links if links.empty?

          presenter = jat_class::LinksPresenter.new(object, context)
          result = links.each_key.each_with_object({}) { |key, data| data[key] = presenter.public_send(key) }
          result.compact!
          result
        end

        def get_meta
          meta = jat_class.added_object_meta
          return meta if meta.empty?

          presenter = jat_class::MetaPresenter.new(object, context)
          result = meta.each_key.each_with_object({}) { |key, data| data[key] = presenter.public_send(key) }
          result.compact!
          result
        end

        def get_relationship_links(rel_serializer, rel_object)
          links = rel_serializer.relationship_links
          return links if links.empty?

          presenter = rel_serializer::RelationshipLinksPresenter.new(object, rel_object, context)
          result = links.each_key.each_with_object({}) { |key, data| data[key] = presenter.public_send(key) }
          result.compact!
          result
        end

        def get_relationship_meta(rel_serializer, rel_object)
          meta = rel_serializer.added_relationship_meta
          return meta if meta.empty?

          presenter = rel_serializer::RelationshipMetaPresenter.new(object, rel_object, context)
          result = meta.each_key.each_with_object({}) { |key, data| data[key] = presenter.public_send(key) }
          result.compact!
          result
        end
      end
    end
  end
end
