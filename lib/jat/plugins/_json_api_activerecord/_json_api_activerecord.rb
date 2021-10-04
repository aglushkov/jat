# frozen_string_literal: true

require_relative "./lib/preloads"

class Jat
  module Plugins
    module JsonApiActiverecord
      def self.apply(jat_class)
        jat_class.extend(ClassMethods)
      end

      def self.after_apply(jat_class, **opts)
        jat_class.plugin :_preloads, **opts
        jat_class.plugin :_activerecord_preloads, **opts
      end

      module ClassMethods
        def jat_preloads(jat)
          Preloads.call(jat)
        end
      end
    end

    register_plugin(:_json_api_activerecord, JsonApiActiverecord)
  end
end
