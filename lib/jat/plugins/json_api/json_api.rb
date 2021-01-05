# frozen_string_literal: true

require_relative "./lib/response"
require_relative "./lib/traversal_map"

# Serializes to JSON-API format
class Jat
  module Plugins
    module JsonApi
      def self.after_load(jat_class, **opts)
        jat_class.plugin(:_json_api_activerecord, **opts) if opts.delete(:activerecord)
      end

      module InstanceMethods
        def to_h
          Response.new(self).response
        end

        def traversal_map
          @traversal_map ||= TraversalMap.new(self)
        end
      end

      module ClassMethods
        def inherited(subclass)
          subclass.type(@type) if defined?(@type)

          super
        end

        def type(new_type = nil)
          return (defined?(@type) && @type) || raise(Error, "#{self} has no defined type") unless new_type

          new_type = new_type.to_sym
          @type = new_type
        end

        def relationship(name, serializer:, **opts, &block)
          attribute(name, {**opts, serializer: serializer}, &block)
        end
      end
    end

    register_plugin(:json_api, JsonApi)
  end
end
