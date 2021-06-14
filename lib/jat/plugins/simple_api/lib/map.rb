# frozen_string_literal: true

require_relative "./params/parse"
require_relative "./construct_traversal_map"

class Jat
  module Plugins
    module SimpleApi
      class Map
        class << self
          # Returns structure like
          # {
          #   key1 => { key11 => {}, key12 => { ... } },
          #   key2 => { key21 => {}, key22 => { ... } },
          # }
          def call(jat)
            params = jat.context[:params]
            fields = params && (params[:fields] || params["fields"])
            exposed = jat.context[:exposed] || :default

            manually_exposed = Params::Parse.new(fields).parse

            ConstructTraversalMap.new(jat.class, exposed, manually_exposed: manually_exposed).to_h
          end
        end
      end
    end
  end
end
