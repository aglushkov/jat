# frozen_string_literal: true

class Jat
  class ResponseData
    attr_reader :serializer, :object, :presenter, :includes

    def initialize(serializer, object, includes)
      @serializer = serializer
      @object = object
      @presenter = serializer.class::Presenter.new(object, serializer._context)
      @includes = includes
    end

    def data
      return unless object

      result = uid
      result[:attributes] = attributes
      result[:relationships] = relationships
      result.compact
    end

    def uid
      { type: serializer.class.type, id: presenter.id }
    end

    private

    def attributes
      attributes_names = serializer._map[:attributes]
      return if attributes_names.empty?

      attributes_names.each_with_object({}) do |name, attrs|
        attribute = serializer.class.attributes[name]
        attrs[name] = presenter.public_send(attribute.original_name)
      end
    end

    def relationships
      relationships_names = serializer._map[:relationships]
      return if relationships_names.empty?

      relationships_names.each_with_object({}) do |name, rels|
        rels[name] = { data: relationship_data(name) }
      end
    end

    def relationship_data(name)
      rel_attribute = serializer.class.attributes[name]
      rel_object = presenter.public_send(rel_attribute.original_name)

      if many?(rel_attribute, rel_object)
        many_relationships_data(rel_object, rel_attribute)
      else
        one_relationship_data(rel_object, rel_attribute)
      end
    end

    def many_relationships_data(rel_objects, rel_attribute)
      return [] if rel_objects.empty?

      rel_serializer = serializer._copy_to(rel_attribute.serializer)

      rel_objects.map { |rel_object| add_relationship_data(rel_serializer, rel_object) }
    end

    def one_relationship_data(rel_object, rel_attribute)
      return unless rel_object

      rel_serializer = serializer._copy_to(rel_attribute.serializer)
      add_relationship_data(rel_serializer, rel_object)
    end

    def add_relationship_data(rel_serializer, rel_object)
      rel_response_data = self.class.new(rel_serializer, rel_object, includes)
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
  end
end
