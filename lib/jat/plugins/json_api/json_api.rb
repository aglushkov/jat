# frozen_string_literal: true

require_relative "./lib/response"
require_relative "./lib/traversal_map"

# Serializes to JSON-API format
class Jat
  module Plugins
    module JsonApi
      def self.apply(jat_class)
        jat_class.include(InstanceMethods)
        jat_class.extend(ClassMethods)
      end

      def self.after_apply(jat_class, **opts)
        jat_class.plugin(:_json_api_activerecord, **opts) if opts[:activerecord]
        jat_class.attribute :id
      end

      module InstanceMethods
        def to_h
          Response.new(self).response
        end

        def traversal_map
          @traversal_map ||= TraversalMap.new(self)
        end
      end

      module ClassMethods
        def inherited(subclass)
          super

          subclass.type(@type) if defined?(@type)

          # Assign same jsonapi_data
          jsonapi_data.each_value do |attribute|
            params = attribute.params
            subclass.jsonapi(params[:name], **params[:opts], &params[:block])
          end

          # Assign same object_links
          object_links.each_value do |attribute|
            params = attribute.params
            subclass.object_link(params[:name], **params[:opts], &params[:block])
          end

          # Assign same document_links
          document_links.each_value do |attribute|
            params = attribute.params
            subclass.document_link(params[:name], **params[:opts], &params[:block])
          end

          # Assign same relationship_links
          relationship_links.each_value do |attribute|
            params = attribute.params
            subclass.relationship_link(params[:name], **params[:opts], &params[:block])
          end

          # Assign same added_object_meta
          added_object_meta.each_value do |attribute|
            params = attribute.params
            subclass.object_meta(params[:name], **params[:opts], &params[:block])
          end

          # Assign same added_document_meta
          added_document_meta.each_value do |attribute|
            params = attribute.params
            subclass.document_meta(params[:name], **params[:opts], &params[:block])
          end

          # Assign same added_document_meta
          added_relationship_meta.each_value do |attribute|
            params = attribute.params
            subclass.relationship_meta(params[:name], **params[:opts], &params[:block])
          end
        end

        def type(new_type = nil)
          return (defined?(@type) && @type) || raise(Error, "#{self} has no defined type") unless new_type

          new_type = new_type.to_sym
          @type = new_type
        end

        def relationship(name, serializer:, **opts, &block)
          attribute(name, serializer: serializer, **opts, &block)
        end

        # JSON API block values
        #
        # https://jsonapi.org/format/#document-jsonapi-object
        def jsonapi_data(_value = nil)
          @jsonapi_data ||= {}
        end

        def jsonapi(name, **opts, &block)
          new_attr = self::Attribute.new(name: name, opts: opts, block: block)
          jsonapi_data[new_attr.name] = new_attr
        end

        # Links related to the resource
        #
        # https://jsonapi.org/format/#document-resource-object-links
        def object_links
          @object_links ||= {}
        end

        def object_link(name, **opts, &block)
          new_attr = self::Attribute.new(name: name, opts: opts, block: block)
          object_links[new_attr.name] = new_attr
        end

        # Top-level document links
        #
        # https://jsonapi.org/format/#document-top-level
        def document_links
          @document_links ||= {}
        end

        def document_link(name, **opts, &block)
          new_attr = self::Attribute.new(name: name, opts: opts, block: block)
          document_links[new_attr.name] = new_attr
        end

        # Relationship links
        #
        # https://jsonapi.org/format/#document-resource-object-linkage
        def relationship_links
          @relationship_links ||= {}
        end

        def relationship_link(name, **opts, &block)
          new_attr = self::Attribute.new(name: name, opts: opts, block: block)
          relationship_links[new_attr.name] = new_attr
        end

        # Object meta
        #
        # https://jsonapi.org/format/#document-resource-objects
        def added_object_meta
          @added_object_meta ||= {}
        end

        def object_meta(name, **opts, &block)
          new_attr = self::Attribute.new(name: name, opts: opts, block: block)
          added_object_meta[new_attr.name] = new_attr
        end

        # Top-level document meta
        #
        # https://jsonapi.org/format/#document-meta
        def added_document_meta
          @added_document_meta ||= {}
        end

        def document_meta(name, **opts, &block)
          new_attr = self::Attribute.new(name: name, opts: opts, block: block)
          added_document_meta[new_attr.name] = new_attr
        end

        # Relationship meta
        #
        # https://jsonapi.org/format/#document-resource-object-relationships
        def added_relationship_meta
          @added_relationship_meta ||= {}
        end

        def relationship_meta(name, **opts, &block)
          new_attr = self::Attribute.new(name: name, opts: opts, block: block)
          added_relationship_meta[new_attr.name] = new_attr
        end
      end
    end

    register_plugin(:json_api, JsonApi)
  end
end
