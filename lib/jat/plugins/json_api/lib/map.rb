# frozen_string_literal: true

class Jat
  module Plugins
    module JsonApi
      class Map
        module ClassMethods
          # Returns structure like
          # {
          #   type1 => {
          #     attributes: [attr1, attr2, ...],
          #     relationships: [rel1, rel2, ...]
          #   },
          #   type2 => { ... }
          # }
          def call(context)
            exposed = context[:exposed]&.to_sym || :default
            fields = context[:fields]
            includes = context[:include]

            construct_map(exposed, fields, includes)
          end

          private

          def construct_map(exposed, fields, includes)
            fields = serializer_class::FieldsParamParser.parse(fields) if fields
            includes = serializer_class::IncludeParamParser.parse(includes) if includes

            new(exposed, fields, includes).to_h
          end
        end

        module InstanceMethods
          attr_reader :serializer_class, :exposed, :includes, :fields

          EXPOSED_TYPES = {all: :all, default: :default, none: :none}.freeze

          def initialize(exposed, fields, includes)
            @serializer_class = self.class.serializer_class
            @exposed = EXPOSED_TYPES.fetch(exposed)
            @fields = fields
            @includes = includes
          end

          def to_h
            map = {}
            append_map(map, serializer_class)
            map
          end

          private

          def append_map(map, serializer_class)
            type = serializer_class.get_type
            return map if map.key?(type)

            type_map = {serializer: serializer_class}
            map[type] = type_map

            fill_type_map(map, type_map, type, serializer_class)

            type_map[:attributes] ||= FROZEN_EMPTY_ARRAY
            type_map[:relationships] ||= FROZEN_EMPTY_ARRAY
          end

          def fill_type_map(map, type_map, type, serializer_class)
            serializer_class.attributes.each_value do |attribute|
              next unless expose?(type, attribute)

              fill_attr(map, type_map, attribute)
            end
          end

          def fill_attr(map, type_map, attribute)
            name = attribute.serialized_name

            if attribute.relation?
              (type_map[:relationships] ||= []) << name
              append_map(map, attribute.serializer)
            else
              (type_map[:attributes] ||= []) << name
            end
          end

          def expose?(type, attribute)
            attribute_name = attribute.serialized_name
            fields_attribute_names = fields && fields[type]
            return fields_attribute_names.include?(attribute_name) if fields_attribute_names

            includes_attribute_names = includes && includes[type]
            includes_attribute_names&.include?(attribute_name) || attribute_exposed?(attribute)
          end

          def attribute_exposed?(attribute)
            return true if exposed == :all
            return false if exposed == :none

            attribute.exposed?
          end
        end

        extend Jat::Helpers::SerializerClassHelper
        extend ClassMethods
        include InstanceMethods
      end
    end
  end
end
