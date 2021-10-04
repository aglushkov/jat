# frozen_string_literal: true

require_relative "./lib/map"
require_relative "./lib/response"

class Jat
  module Plugins
    module SimpleApi
      DEFAULT_META_KEY = :meta

      def self.apply(jat_class)
        jat_class.include(InstanceMethods)
        jat_class.extend(ClassMethods)
      end

      def self.after_apply(jat_class, **opts)
        jat_class.plugin(:_json_api_activerecord, **opts) if opts[:activerecord]

        jat_class.meta_key(DEFAULT_META_KEY)
      end

      module InstanceMethods
        def to_h
          Response.new(self).response
        end

        def traversal_map
          @traversal_map ||= Map.call(self)
        end
      end

      module ClassMethods
        def inherited(subclass)
          super

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
      end
    end

    register_plugin(:simple_api, SimpleApi)
  end
end
