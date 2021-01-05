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
          meta = metadata

          result = {}
          result[:data] = data if data
          result[:included] = includes.values if includes.any?
          result[:meta] = meta if meta.any?
          result
        end

        private

        def data_with_includes
          includes = {}
          data = many?(object, context) ? many(object, includes) : one(object, includes)
          [data, includes]
        end

        def metadata
          result = context[:meta] || {}

          config_meta = jat_class.config[:meta]
          return result unless config_meta

          config_meta.each_with_object(result) do |(key, value), res|
            next if res.key?(key) # do not overwrite manually added meta

            value = value.call(object, context) if value.respond_to?(:call)
            res[key] = value unless value.nil?
          end
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

          result = uid
          result[:attributes] = attributes
          result[:relationships] = relationships
          result.compact
        end

        def uid
          {type: jat_class.type, id: presenter.id}
        end

        private

        def attributes
          attributes_names = map[:attributes]
          return if attributes_names.empty?

          attributes_names.each_with_object({}) do |name, attrs|
            attribute = jat_class.attributes[name]
            attrs[name] = presenter.public_send(attribute.original_name)
          end
        end

        def relationships
          relationships_names = map[:relationships]
          return if relationships_names.empty?

          relationships_names.each_with_object({}) do |name, rels|
            rels[name] = {data: relationship_data(name)}
          end
        end

        def relationship_data(name)
          rel_attribute = jat_class.attributes[name]
          rel_object = presenter.public_send(rel_attribute.original_name)

          if many?(rel_attribute, rel_object)
            many_relationships_data(rel_object, rel_attribute)
          else
            one_relationship_data(rel_object, rel_attribute)
          end
        end

        def many_relationships_data(rel_objects, rel_attribute)
          return [] if rel_objects.empty?

          rel_objects.map { |rel_object| add_relationship_data(rel_attribute, rel_object) }
        end

        def one_relationship_data(rel_object, rel_attribute)
          return unless rel_object

          add_relationship_data(rel_attribute, rel_object)
        end

        def add_relationship_data(rel_attribute, rel_object)
          rel_serializer = rel_attribute.serializer.call
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
      end
    end
  end
end
