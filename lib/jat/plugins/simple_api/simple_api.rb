# frozen_string_literal: true

require_relative "./lib/fields_param_parser"
require_relative "./lib/map"
require_relative "./lib/response"
require_relative "./lib/response_piece"

class Jat
  module Plugins
    module SimpleApi
      def self.plugin_name
        :simple_api
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

      def self.after_load(jat_class, **_opts)
        jat_class.config[:response_plugin_loaded] = plugin_name

        jat_class.meta_key(:meta)

        fields_parser_class = Class.new(FieldsParamParser)
        fields_parser_class.jat_class = jat_class
        jat_class.const_set(:FieldsParamParser, fields_parser_class)

        map_class = Class.new(Map)
        map_class.jat_class = jat_class
        jat_class.const_set(:Map, map_class)

        response_class = Class.new(Response)
        response_class.jat_class = jat_class
        jat_class.const_set(:Response, response_class)

        response_piece_class = Class.new(ResponsePiece)
        response_piece_class.jat_class = jat_class
        jat_class.const_set(:ResponsePiece, response_piece_class)
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

          map_class = Class.new(self::Map)
          map_class.jat_class = subclass
          subclass.const_set(:Map, map_class)

          response_class = Class.new(self::Response)
          response_class.jat_class = subclass
          subclass.const_set(:Response, response_class)

          response_piece_class = Class.new(self::ResponsePiece)
          response_piece_class.jat_class = subclass
          subclass.const_set(:ResponsePiece, response_piece_class)

          # Assign same meta
          added_meta.each_value do |attribute|
            params = attribute.params
            subclass.attribute(params[:name], **params[:opts], &params[:block])
          end
        end

        def root(default = nil, one: nil, many: nil)
          root_one = one || default
          root_many = many || default

          config[:root_one] = root_one ? root_one.to_sym : nil
          config[:root_many] = root_many ? root_many.to_sym : nil

          {root_one: root_one, root_many: root_many}
        end

        def meta_key(new_meta_key)
          config[:meta_key] = new_meta_key.to_sym
        end

        def added_meta
          @added_meta ||= {}
        end

        def meta(name, **opts, &block)
          new_attr = self::Attribute.new(name: name, opts: opts, block: block)
          added_meta[new_attr.name] = new_attr
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

    register_plugin(SimpleApi.plugin_name, SimpleApi)
  end
end
