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
        return requested_fields(serializer, fields) if fields
        return requested_includes_fields(serializer, includes) if includes

        serializer.exposed_map
      end

      private

      def requested_fields(serializer, fields)
        fields_types = Params::Fields.(serializer, fields)

        Construct
          .new(serializer, :none, exposed_additionally: fields_types)
          .to_h
      end

      def requested_includes_fields(serializer, includes)
        include_types = Params::Include.(serializer, includes)

        Construct
          .new(serializer, :default, exposed_additionally: include_types)
          .to_h
      end
    end
  end
end
