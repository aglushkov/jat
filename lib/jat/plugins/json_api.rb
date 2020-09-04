# frozen_string_literal: true

require 'jat/plugins/json_api/map'
require 'jat/plugins/json_api/serialization_map'
require 'jat/plugins/json_api/serializer'

class Jat
  module Plugins
    module JSON_API
      module ClassMethods
        def keys
          @keys ||= {}
        end

        def type(new_type = nil)
          if new_type
            new_type = new_type.to_sym
            define_method(:type) { new_type }
            @type = new_type
          else
            raise Error, "#{self} has no defined type" unless @type
            @type
          end
        end

        def id(field: :id, &block)
          block ||= proc { |obj| obj.public_send(field) }
          define_method(:id, &block)
        end

        def full_map
          @full_map ||= Map.(self, :all)
        end

        def exposed_map
          @exposed_map ||= Map.(self, :exposed)
        end

        def attribute(key, **opts)
          validate_attr(key)

          defaults = { exposed: true }
          opts = defaults.merge!(opts)

          add_key(key, opts)
        end

        def relationship(key, serializer:, **opts)
          validate_rel(key)

          defaults = { exposed: false, many: false }
          opts = defaults.merge!(opts).merge!(serializer: serializer, relationship: true)

          add_key(key, opts)
        end

        def serialize(obj, serializer_class, many: false, meta: nil, params: nil)
          Serializer.(obj, serializer_class, many: many, meta: meta, params: params)
        end

        private

        def add_key(key, opts)
          key = key.to_sym

          clear_maps
          keys[key] = opts
        end

        def clear_maps
          @full_map = nil
          @exposed_map = nil
        end

        def validate_attr(key)
          if (key == :type) || (key == :id) || (key == 'type') || (key == 'id')
            raise Error, "Attribute can't have `#{key}` name"
          end
        end

        def validate_rel(key)
          if (key == :type) || (key == :id) || (key == 'type') || (key == 'id')
            raise Error, "Relationship can't have `#{key}` name"
          end
        end
      end

      # Serializers DSL instance methods
      module InstanceMethods
        def initialize(params = nil, _full_map = nil)
          @_params ||= params

          @_full_map = _full_map || begin
            fields = params && (params[:fields] || params['fields'])
            includes = params && (params[:include] || params['include'])
            SerializationMap.(self.class, fields, includes)
          end

          current_map = @_full_map.fetch(self.class.type)
          @_attributes = current_map[:attributes]
          @_relationships = current_map[:relationships]
        end

        def call(obj, includes, many)
          many ? _many(obj, includes) : _one(obj, includes)
        end

        def _uid(obj)
          { type: type, id: id(obj) }
        end

        def id(obj)
          obj.id
        end

        private

        attr_reader :_attributes, :_relationships

        def _one(obj, includes)
          return unless obj

          result = _uid(obj)
          _assign_attributes(result, obj)
          _assign_relationships(result, obj, includes)
          result
        end

        def _many(objects, includes)
          objects.map { |obj| _one(obj, includes) }
        end

        def _assign_attributes(result, obj)
          return if _attributes.empty?

          result[:attributes] = _attributes.each_with_object({}) do |attribute, attrs|
            attrs[attribute] = public_send(attribute, obj)
          end
        end

        def _assign_relationships(result, obj, includes)
          return if _relationships.empty?

          result[:relationships] = _relationships.each_with_object({}) do |attribute, rels|
            data = _any_relationship_data(obj, attribute, includes)
            rels_attribute = {}
            rels_attribute[:data] = data
            rels[attribute] = rels_attribute
          end
        end

        def _any_relationship_data(obj, attribute, includes)
          rel_object = public_send(attribute, obj)
          opts = self.class.keys[attribute]

          if opts[:many]
            return [] if rel_object.empty?

            _add_relationships_data(rel_object, opts, includes)
          else
            return unless rel_object

            serializer = opts[:serializer].new(@_params, @_full_map)
            _add_relationship_data(rel_object, serializer, includes)
          end
        end

        def _add_relationships_data(objects, opts, includes)
          serializer = opts[:serializer].new(@_params, @_full_map)

          objects.map { |obj| _add_relationship_data(obj, serializer, includes) }
        end

        def _add_relationship_data(obj, serializer, includes)
          uid = serializer._uid(obj)
          includes[uid] ||= serializer.(obj, includes, false)

          uid
        end
      end
    end

    register_plugin(:json_api, JSON_API)
  end
end
