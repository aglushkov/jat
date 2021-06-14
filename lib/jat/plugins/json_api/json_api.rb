# frozen_string_literal: true

require_relative "./lib/response"
require_relative "./lib/traversal_map"
require_relative "./lib/presenters/document_links_presenter"
require_relative "./lib/presenters/document_meta_presenter"
require_relative "./lib/presenters/jsonapi_presenter"
require_relative "./lib/presenters/links_presenter"
require_relative "./lib/presenters/meta_presenter"
require_relative "./lib/presenters/relationship_links_presenter"
require_relative "./lib/presenters/relationship_meta_presenter"

# Serializes to JSON-API format
class Jat
  module Plugins
    module JsonApi
      def self.after_load(jat_class, **opts)
        jat_class.plugin(:_json_api_activerecord, **opts) if opts[:activerecord]

        jat_class.const_set(:JsonapiPresenter, Class.new(Jat::Presenters::JsonapiPresenter))
        jat_class::JsonapiPresenter.jat_class = jat_class

        jat_class.const_set(:LinksPresenter, Class.new(Jat::Presenters::LinksPresenter))
        jat_class::LinksPresenter.jat_class = jat_class

        jat_class.const_set(:DocumentLinksPresenter, Class.new(Jat::Presenters::DocumentLinksPresenter))
        jat_class::DocumentLinksPresenter.jat_class = jat_class

        jat_class.const_set(:RelationshipLinksPresenter, Class.new(Jat::Presenters::RelationshipLinksPresenter))
        jat_class::RelationshipLinksPresenter.jat_class = jat_class

        jat_class.const_set(:MetaPresenter, Class.new(Jat::Presenters::MetaPresenter))
        jat_class::MetaPresenter.jat_class = jat_class

        jat_class.const_set(:DocumentMetaPresenter, Class.new(Jat::Presenters::DocumentMetaPresenter))
        jat_class::DocumentMetaPresenter.jat_class = jat_class

        jat_class.const_set(:RelationshipMetaPresenter, Class.new(Jat::Presenters::RelationshipMetaPresenter))
        jat_class::RelationshipMetaPresenter.jat_class = jat_class
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
          subclass.type(@type) if defined?(@type)

          # Initialize JsonApi data Presenters
          jsonapi_data_presenter_class = Class.new(self::Presenters::JsonapiPresenter)
          jsonapi_data_presenter_class.jat_class = subclass
          subclass.const_set(:JsonapiPresenter, jsonapi_data_presenter_class)
          jsonapi_data.each { |key, block| subclass.jsonapi(key, &block) }

          # Initialize Links Presenters
          links_presenter_class = Class.new(self::Presenters::LinksPresenter)
          links_presenter_class.jat_class = subclass
          subclass.const_set(:LinksPresenter, links_presenter_class)
          object_links.each { |key, block| subclass.object_link(key, &block) }

          # Initialize DocumentLinks Presenters
          document_links_presenter_class = Class.new(self::Presenters::DocumentLinksPresenter)
          document_links_presenter_class.jat_class = subclass
          subclass.const_set(:DocumentLinksPresenter, document_links_presenter_class)
          document_links.each { |key, block| subclass.document_link(key, &block) }

          # Initialize RelationshipLinks Presenters
          relationship_links_presenter_class = Class.new(self::Presenters::RelationshipLinksPresenter)
          relationship_links_presenter_class.jat_class = subclass
          subclass.const_set(:RelationshipLinksPresenter, relationship_links_presenter_class)
          relationship_links.each { |key, block| subclass.relationship_link(key, &block) }

          # Initialize Meta Presenters
          meta_presenter_class = Class.new(self::Presenters::MetaPresenter)
          meta_presenter_class.jat_class = subclass
          subclass.const_set(:MetaPresenter, meta_presenter_class)
          added_object_meta.each { |key, block| subclass.object_meta(key, &block) }

          # Initialize DocumentMeta Presenters
          document_meta_presenter_class = Class.new(self::Presenters::DocumentMetaPresenter)
          document_meta_presenter_class.jat_class = subclass
          subclass.const_set(:DocumentMetaPresenter, document_meta_presenter_class)
          added_document_meta.each { |key, block| subclass.document_meta(key, &block) }

          # Initialize RelationshipMeta Presenters
          relationship_meta_presenter_class = Class.new(self::Presenters::RelationshipMetaPresenter)
          relationship_meta_presenter_class.jat_class = subclass
          subclass.const_set(:RelationshipMetaPresenter, relationship_meta_presenter_class)
          added_relationship_meta.each { |key, block| subclass.relationship_meta(key, &block) }

          super
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
        def jsonapi_data(value = nil)
          @jsonapi_data ||= {}
        end

        def jsonapi(key, &block)
          jsonapi_data[key.to_sym] = block
          self::JsonapiPresenter.add_method(key, block)
          block
        end

        # Links related to the resource
        #
        # https://jsonapi.org/format/#document-resource-object-links
        def object_links
          @object_links ||= {}
        end

        def object_link(key, &block)
          object_links[key.to_sym] = block
          self::LinksPresenter.add_method(key, block)
          block
        end

        # Top-level document links
        #
        # https://jsonapi.org/format/#document-top-level
        def document_links
          @document_links ||= {}
        end

        def document_link(key, &block)
          document_links[key.to_sym] = block
          self::DocumentLinksPresenter.add_method(key, block)
          block
        end

        # Relationship links
        #
        # https://jsonapi.org/format/#document-resource-object-linkage
        def relationship_links
          @relationship_links ||= {}
        end

        def relationship_link(key, &block)
          relationship_links[key.to_sym] = block
          self::RelationshipLinksPresenter.add_method(key, block)
          block
        end

        # Object meta
        #
        # https://jsonapi.org/format/#document-resource-objects
        def added_object_meta
          @added_object_meta ||= {}
        end

        def object_meta(key, &block)
          added_object_meta[key.to_sym] = block
          self::MetaPresenter.add_method(key, block)
          block
        end

        # Top-level document meta
        #
        # https://jsonapi.org/format/#document-meta
        def added_document_meta
          @added_document_meta ||= {}
        end

        def document_meta(key, &block)
          added_document_meta[key.to_sym] = block
          self::DocumentMetaPresenter.add_method(key, block)
          block
        end

        # Relationship meta
        #
        # https://jsonapi.org/format/#document-resource-object-relationships
        def added_relationship_meta
          @added_relationship_meta ||= {}
        end

        def relationship_meta(key, &block)
          added_relationship_meta[key.to_sym] = block
          self::RelationshipMetaPresenter.add_method(key, block)
          block
        end
      end
    end

    register_plugin(:json_api, JsonApi)
  end
end
