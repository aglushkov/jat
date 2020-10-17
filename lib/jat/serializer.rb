# frozen_string_literal: true

# Serializes to JSON-API format
class Jat
  class Serializer
    attr_reader :includes

    def initialize(includes)
      @includes = includes
    end

    def data(serializer, object)
      return unless object

      result = uid(serializer, object)
      result[:attributes] = attributes(serializer, object)
      result[:relationships] = relationships(serializer, object)
      result.compact
    end

    private

    def uid(serializer, object)
      { type: serializer.type, id: serializer.id(object) }
    end

    def attributes(serializer, object)
      attributes_names = serializer._map[:attributes]
      return if attributes_names.empty?

      attributes_names.each_with_object({}) do |name, attrs|
        attrs[name] = serializer.public_send(name, object, serializer._params)
      end
    end

    def relationships(serializer, object)
      relationships_names = serializer._map[:relationships]
      return if relationships_names.empty?

      relationships_names.each_with_object({}) do |name, rels|
        rels[name] = { data: relationship_data(serializer, object, name) }
      end
    end

    def relationship_data(serializer, object, name)
      rel_object = serializer.public_send(name, object, serializer._params)
      attribute = serializer.class.attributes[name]

      if attribute.many?
        many_relationships_data(serializer, rel_object, attribute)
      else
        one_relationship_data(serializer, rel_object, attribute)
      end
    end

    def many_relationships_data(serializer, rel_objects, attribute)
      return [] if rel_objects.empty?

      rel_serializer = attribute.serializer.inherited_instance(serializer)

      rel_objects.map { |rel_object| add_relationship_data(rel_serializer, rel_object) }
    end

    def one_relationship_data(serializer, rel_object, attribute)
      return unless rel_object

      rel_serializer = attribute.serializer.inherited_instance(serializer)
      add_relationship_data(rel_serializer, rel_object)
    end

    def add_relationship_data(rel_serializer, rel_object)
      rel_uid = uid(rel_serializer, rel_object)
      includes[rel_uid] ||= data(rel_serializer, rel_object)
      rel_uid
    end

    class << self
      def call(object, serializer, opts = {})
        includes = {}

        data = opts[:many] ? many(includes, serializer, object) : one(includes, serializer, object)

        response(data, includes, opts[:meta])
      end

      private

      def response(data, includes, meta)
        result = {}
        result[:data] = data if data
        result[:included] = includes.values unless includes == {}
        result[:meta] = meta if meta
        result
      end

      def many(includes, serializer, objects)
        objects.map { |object| one(includes, serializer, object) }
      end

      def one(includes, initial_serializer, initial_object)
        new(includes).data(initial_serializer, initial_object)
      end
    end
  end
end
