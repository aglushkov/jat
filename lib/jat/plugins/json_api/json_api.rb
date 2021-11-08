# frozen_string_literal: true

require_relative "./lib/fields_param_parser"
require_relative "./lib/include_param_parser"
require_relative "./lib/map"
require_relative "./lib/response"
require_relative "./lib/response_piece"

# Serializes to JSON-API format
class Jat
  module Plugins
    module JsonApi
      def self.plugin_name
        :json_api
      end

      def self.before_load(jat_class, **_opts)
        response_plugin = jat_class.config[:response_plugin_loaded]
        return unless response_plugin

        raise Error, "Response plugin `#{response_plugin}` was already loaded before"
      end

      def self.load(jat_class, **_opts)
        jat_class.include(InstanceMethods)
        jat_class.extend(ClassMethods)
      end

      def self.after_load(jat_class, **opts)
        jat_class.config[:response_plugin_loaded] = plugin_name

        fields_parser_class = Class.new(FieldsParamParser)
        fields_parser_class.jat_class = jat_class
        jat_class.const_set(:FieldsParamParser, fields_parser_class)

        includes_parser_class = Class.new(IncludeParamParser)
        includes_parser_class.jat_class = jat_class
        jat_class.const_set(:IncludeParamParser, includes_parser_class)

        map_class = Class.new(Map)
        map_class.jat_class = jat_class
        jat_class.const_set(:Map, map_class)

        response_class = Class.new(Response)
        response_class.jat_class = jat_class
        jat_class.const_set(:Response, response_class)

        response_piece_class = Class.new(ResponsePiece)
        response_piece_class.jat_class = jat_class
        jat_class.const_set(:ResponsePiece, response_piece_class)

        jat_class.id
      end

      module InstanceMethods
        def to_h(object)
          self.class::Response.call(object, context)
        end

        def map
          @map ||= self.class.map(context)
        end
      end

      module ClassMethods
        def inherited(subclass)
          super

          fields_parser_class = Class.new(self::FieldsParamParser)
          fields_parser_class.jat_class = subclass
          subclass.const_set(:FieldsParamParser, fields_parser_class)

          includes_parser_class = Class.new(self::IncludeParamParser)
          includes_parser_class.jat_class = subclass
          subclass.const_set(:IncludeParamParser, includes_parser_class)

          map_class = Class.new(self::Map)
          map_class.jat_class = subclass
          subclass.const_set(:Map, map_class)

          response_class = Class.new(self::Response)
          response_class.jat_class = subclass
          subclass.const_set(:Response, response_class)

          response_piece_class = Class.new(self::ResponsePiece)
          response_piece_class.jat_class = subclass
          subclass.const_set(:ResponsePiece, response_piece_class)

          subclass.type(@type) if defined?(@type)
          subclass.id(&get_id.params[:block])

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

          # Assign same added_relationship_meta
          added_relationship_meta.each_value do |attribute|
            params = attribute.params
            subclass.relationship_meta(params[:name], **params[:opts], &params[:block])
          end
        end

        def get_type
          (defined?(@type) && @type) || raise(Error, "#{self} has no defined type")
        end

        def type(new_type)
          @type = new_type.to_sym
        end

        def get_id
          @id
        end

        def id(**opts, &block)
          @id = self::Attribute.new(name: :id, opts: opts, block: block)
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

        def map(context)
          self::Map.call(context)
        end

        def map_full
          @map_full ||= self::Map.call(exposed: :all)
        end

        def map_exposed
          @map_exposed ||= self::Map.call(exposed: :default)
        end
      end
    end

    register_plugin(JsonApi.plugin_name, JsonApi)
  end
end
