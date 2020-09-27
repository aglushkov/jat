# frozen_string_literal: true

require 'jat/plugins/json_api/map'
require 'jat/plugins/json_api/serialization_map'
require 'jat/plugins/json_api/serializer'

class Jat
  module Plugins
    module JSON_API
      module ClassMethods
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

        def attribute(key, **opts, &block)
          validate_attr(key)

          defaults = { exposed: true }
          opts = defaults.merge!(opts)

          add_key(key, opts, &block).tap { clear_maps }
        end

        def relationship(key, serializer:, **opts, &block)
          validate_rel(key)

          defaults = { exposed: false, many: false }
          opts = defaults.merge!(opts).merge!(serializer: serializer, relationship: true)

          add_key(key, opts, &block).tap { clear_maps }
        end

        private

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
        attr_reader :_params, :_full_map, :_attributes, :_relationships

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

        def to_h(obj, many: false, meta: nil)
          Serializer.(obj, self, many: many, meta: meta)
        end

        def id(obj)
          obj.id
        end
      end
    end

    register_plugin(:json_api, JSON_API)
  end
end
