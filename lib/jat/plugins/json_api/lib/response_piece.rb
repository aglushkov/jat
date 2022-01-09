# frozen_string_literal: true

class Jat
  module Plugins
    module JsonApi
      class ResponsePiece
        module ClassMethods
          # Returns the Jat class that this ResponsePiece class is namespaced under.
          attr_accessor :jat_class

          # Since ResponsePiece is anonymously subclassed when Jat is subclassed,
          # and then assigned to a constant of the Jat subclass, make inspect
          # reflect the likely name for the class.
          def inspect
            "#{jat_class.inspect}::ResponsePiece"
          end

          def call(object, context, map, includes)
            new(object, context, map, includes).to_h
          end
        end

        module InstanceMethods
          attr_reader :jat_class, :object, :context, :map, :type_map, :includes

          def initialize(object, context, map, includes)
            @jat_class = self.class.jat_class
            @object = object
            @context = context
            @map = map
            @type_map = map.fetch(jat_class.get_type)
            @includes = includes
          end

          def to_h
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
            {type: type, id: id}
          end

          private

          def get_attributes
            attributes_names = type_map[:attributes]
            return if attributes_names.empty?

            attributes_names.each_with_object({}) do |name, attrs|
              attribute = jat_class.attributes[name]
              attrs[name] = attribute.value(object, context)
            end
          end

          def get_relationships
            relationships_names = type_map[:relationships]
            return if relationships_names.empty?

            relationships_names.each_with_object({}) do |name, rels|
              rel_attribute = jat_class.attributes[name]
              rel_object = rel_attribute.value(object, context)

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
            return FROZEN_EMPTY_ARRAY if rel_objects.empty?

            rel_objects.map { |rel_object| add_relationship_data(rel_serializer, rel_object) }
          end

          def one_relationship_data(rel_serializer, rel_object)
            return unless rel_object

            add_relationship_data(rel_serializer, rel_object)
          end

          def add_relationship_data(rel_serializer, rel_object)
            rel_response_data = rel_serializer::ResponsePiece.new(rel_object, context, map, includes)
            rel_uid = rel_response_data.uid
            simple_uid = "#{rel_uid[:id]}-#{rel_uid[:type]}"
            includes[simple_uid] ||= rel_response_data.to_h
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
              .transform_values { |attr| attr.value(object, context) }
              .tap(&:compact!)
          end

          def get_meta
            jat_class
              .added_object_meta
              .transform_values { |attr| attr.value(object, context) }
              .tap(&:compact!)
          end

          def get_relationship_links(rel_serializer, rel_object)
            links = rel_serializer.relationship_links
            return FROZEN_EMPTY_HASH if links.empty?

            context[:parent_object] = object

            links
              .transform_values { |attr| attr.value(rel_object, context) }
              .tap(&:compact!)
              .tap { context.delete(:parent_object) }
          end

          def get_relationship_meta(rel_serializer, rel_object)
            meta = rel_serializer.added_relationship_meta
            return FROZEN_EMPTY_HASH if meta.empty?

            context[:parent_object] = object

            meta
              .transform_values { |attr| attr.value(rel_object, context) }
              .tap(&:compact!)
              .tap { context.delete(:parent_object) }
          end

          def type
            @type ||= jat_class.get_type
          end

          def id
            @id ||= jat_class.get_id.value(object, context)
          end
        end

        extend ClassMethods
        include InstanceMethods
      end
    end
  end
end
