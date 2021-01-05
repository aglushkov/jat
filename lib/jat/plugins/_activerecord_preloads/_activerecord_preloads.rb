# frozen_string_literal: true

require_relative "./lib/preloader"

class Jat
  module Plugins
    module ActiverecordPreloads
      module InstanceMethods
        def initialize(*)
          super
          @object = add_preloads(@object)
        end

        private

        def add_preloads(obj)
          return obj if obj.nil? || (obj.is_a?(Array) && obj.empty?)

          preloads = self.class.jat_preloads(self)
          return obj if preloads.empty?

          Preloader.preload(obj, preloads)
        end
      end
    end

    register_plugin(:_activerecord_preloads, ActiverecordPreloads)
  end
end
