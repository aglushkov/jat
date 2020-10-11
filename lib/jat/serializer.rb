# frozen_string_literal: true

# Serializes to JSON-API format
class Jat
  class Serializer
    class << self
      def call(object, serializer, many: false, meta: nil)
        includes = {}
        data = data(object, serializer, many, includes)

        response = {}
        response[:data] = data if data
        response[:included] = includes.values unless includes.empty?
        response[:meta] = meta if meta
        response
      end

      private

      def data(object, serializer, many, includes)
        many ? many(object, serializer, includes) : one(object, serializer, includes)
      end

      def uid(obj, serializer)
        { type: serializer.type, id: serializer.id(obj) }
      end

      def one(obj, serializer, includes)
        return unless obj

        result = uid(obj, serializer)
        assign_attributes(result, obj, serializer)
        assign_relationships(result, obj, serializer, includes)
        result
      end

      def many(objects, serializer, includes)
        objects.map { |obj| one(obj, serializer, includes) }
      end

      def assign_attributes(result, obj, serializer)
        attributes = serializer._map[:attributes]
        return if attributes.empty?

        result[:attributes] = attributes.each_with_object({}) do |attr, attrs|
          attrs[attr] = serializer.public_send(attr, obj, serializer._params)
        end
      end

      def assign_relationships(result, obj, serializer, includes)
        relationships = serializer._map[:relationships]
        return if relationships.empty?

        result[:relationships] = relationships.each_with_object({}) do |attr, rels|
          rels[attr] = { data: relationship_data(obj, serializer, attr, includes) }
        end
      end

      def relationship_data(obj, serializer, attr, includes)
        rel_object = serializer.public_send(attr, obj, serializer._params)
        opts = serializer.class.attrs[attr]

        if opts.many?
          return [] if rel_object.empty?

          add_relationships_data(rel_object, serializer, opts, includes)
        else
          return unless rel_object

          rel_serializer = opts.serializer.new(serializer._params, serializer._full_map)
          add_relationship_data(rel_object, rel_serializer, includes)
        end
      end

      def add_relationships_data(objects, serializer, opts, includes)
        rel_serializer = opts.serializer.new(serializer._params, serializer._full_map)

        objects.map { |obj| add_relationship_data(obj, rel_serializer, includes) }
      end

      def add_relationship_data(obj, rel_serializer, includes)
        rel_uid = uid(obj, rel_serializer)
        includes[rel_uid] ||= data(obj, rel_serializer, false, includes)

        rel_uid
      end
    end
  end
end
