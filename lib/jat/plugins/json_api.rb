# frozen_string_literal: true

require 'jat/plugins/json_api/map'
require 'jat/plugins/json_api/serialization_map'
require 'jat/plugins/json_api/serializer'
require 'jat/plugins/json_api/check_key'

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

        def attribute(name, **opts, &block)
          opts = prepare_attributes_opts(opts)
          key(name, opts, &block).tap { clear_maps }
        end

        def relationship(name, serializer:, **opts, &block)
          opts = prepare_relationship_opts(serializer, opts)
          key(name, opts, &block).tap { clear_maps }
        end

        private

        def clear_maps
          @full_map = nil
          @exposed_map = nil
        end

        def prepare_attributes_opts(opts)
          defaults = { exposed: true }
          defaults.merge!(opts)
        end

        def prepare_relationship_opts(serializer, opts)
          defaults = { exposed: false, many: false }
          defaults.merge!(opts).merge!(relationship: true, serializer: serializer)
        end
      end

      # Serializers DSL instance methods
      module InstanceMethods
        attr_reader :_params, :_attributes, :_relationships

        def initialize(params = nil, _prev_full_map = nil)
          @_params ||= params
          @_full_map = _prev_full_map if _prev_full_map

          current_map = _full_map.fetch(self.class.type)
          @_attributes = current_map[:attributes]
          @_relationships = current_map[:relationships]
        end

        def to_h(obj, many: false, meta: nil)
          Serializer.(obj, self, many: many, meta: meta)
        end

        def id(obj)
          obj.id
        end

        def _full_map
          @_full_map ||= begin
            fields = _params && (_params[:fields] || _params['fields'])
            includes = _params && (_params[:include] || _params['include'])
            SerializationMap.(self.class, fields, includes)
          end
        end

        def _includes
          Includes.(_full_map)
        end
      end
    end

    register_plugin(:json_api, JSON_API)
  end
end
