# frozen_string_literal: true

require 'jat/params/fields'
require 'jat/params/include'

class Jat
  class Map
    # This must return structure like
    # {
    #   type => {
    #     attributes: [attr1, attr2, ...],
    #     relationships: [rel1, rel2, ...]
    #   }
    # }
    class << self
      def call(serializer, fields, includes)
        default_attrs = serializer.exposed_map
        includes_attrs = requested_includes_fields(serializer, includes)
        fields_attrs = requested_fields(serializer, fields)

        default_attrs.merge!(includes_attrs).merge!(fields_attrs)
      end

      private

      def requested_fields(serializer, fields)
        return {} unless fields

        fields_types = Params::Fields.(serializer, fields)
        Construct
          .new(serializer, :manual, manually_exposed: fields_types)
          .to_h
      end

      def requested_includes_fields(serializer, includes)
        return {} unless includes

        include_types = Params::Include.(serializer, includes)
        Construct
          .new(serializer, :exposed, manually_exposed: include_types)
          .to_h
      end
    end
  end
end
