# frozen_string_literal: true

require_relative "./lib/map"
require_relative "./lib/response"

# Serializes to JSON-API format
class Jat
  module Plugins
    module SimpleApi
      DEFAULT_META_KEY = :meta

      def self.after_load(jat_class, **opts)
        jat_class.plugin(:_json_api_activerecord, **opts) if opts[:activerecord]
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
          subclass.root(@root) if defined?(@root)

          super
        end

        def root(new_root = nil)
          return (defined?(@root) && @root) unless new_root

          new_root = new_root.to_sym
          @root = new_root
        end

        def root_for_one(new_root_for_one = nil)
          return (defined?(@root_for_one) && @root_for_one) unless new_root_for_one

          new_root_for_one = new_root_for_one.to_sym
          @root_for_one = new_root_for_one
        end

        def root_for_many(new_root_for_many = nil)
          return (defined?(@root_for_many) && @root_for_many) unless new_root_for_many

          new_root_for_many = new_root_for_many.to_sym
          @root_for_many = new_root_for_many
        end

        def meta_key(new_meta_key = nil)
          return ((defined?(@meta_key) && @meta_key) || DEFAULT_META_KEY) unless new_meta_key

          new_meta_key = new_meta_key.to_sym
          @meta_key = new_meta_key
        end
      end
    end

    register_plugin(:simple_api, SimpleApi)
  end
end
