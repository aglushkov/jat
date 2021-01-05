# frozen_string_literal: true

require_relative "./construct_traversal_map"
require_relative "./map"

class Jat
  module Plugins
    module JsonApi
      class TraversalMap
        module InstanceMethods
          attr_reader :jat

          def initialize(jat)
            @jat = jat
          end

          def full
            @full ||= ConstructTraversalMap.new(jat.class, :all).to_h
          end

          def exposed
            @exposed ||= ConstructTraversalMap.new(jat.class, :exposed).to_h
          end

          def current
            @current ||= Map.call(jat)
          end
        end

        include InstanceMethods
      end
    end
  end
end
