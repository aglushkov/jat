# frozen_string_literal: true

require_relative "./lib/preloader"

class Jat
  module Plugins
    module ActiverecordPreloads
      def self.load(jat_class, **_opts)
        jat_class.include(InstanceMethods)
      end

      module InstanceMethods
        def to_h(object)
          object = add_preloads(object)
          super
        end

        private

        def add_preloads(obj)
          return obj if obj.nil? || (obj.is_a?(Array) && obj.empty?)

          preloads = preloads()
          return obj if preloads.empty?

          Preloader.preload(obj, preloads)
        end
      end
    end

    register_plugin(:_activerecord_preloads, ActiverecordPreloads)
  end
end
