# frozen_string_literal: true

require_relative "./params/fields"
require_relative "./params/include"
require_relative "./construct_traversal_map"

class Jat
  module Plugins
    module JsonApi
      class Map
        class << self
          # Returns structure like
          # {
          #   type => {
          #     attributes: [attr1, attr2, ...],
          #     relationships: [rel1, rel2, ...]
          #   }
          # }
          def call(jat)
            params = jat.context[:params]
            fields = params && (params[:fields] || params["fields"])
            includes = params && (params[:include] || params["include"])

            default_attrs = jat.traversal_map.exposed
            includes_attrs = requested_includes_fields(jat, includes)
            fields_attrs = requested_fields(jat, fields)

            default_attrs.merge!(includes_attrs).merge!(fields_attrs)
          end

          private

          def requested_includes_fields(jat, includes)
            return {} unless includes

            include_types = Params::Include.call(jat, includes)
            ConstructTraversalMap
              .new(jat.class, :exposed, manually_exposed: include_types)
              .to_h
          end

          def requested_fields(jat, fields)
            return {} unless fields

            fields_types = Params::Fields.call(jat, fields)
            ConstructTraversalMap
              .new(jat.class, :manual, manually_exposed: fields_types)
              .to_h
          end
        end
      end
    end
  end
end
