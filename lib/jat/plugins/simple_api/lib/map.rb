# frozen_string_literal: true

class Jat
  module Plugins
    module SimpleApi
      class Map
        module ClassMethods
          # Returns structure like
          # {
          #   key1 => { key11 => {}, key12 => { ... } },
          #   key2 => { key21 => {}, key22 => { ... } },
          # }
          def call(context)
            exposed = context[:exposed]&.to_sym || :default
            fields = context[:fields]

            construct_map(exposed, fields)
          end

          private

          def construct_map(exposed, fields)
            fields = serializer_class::FieldsParamParser.parse(fields) if fields
            new(exposed, fields).to_h
          end
        end

        module InstanceMethods
          attr_reader :exposed, :fields

          EXPOSED_TYPES = {all: :all, default: :default, none: :none}.freeze

          def initialize(exposed, fields)
            @exposed = EXPOSED_TYPES.fetch(exposed)
            @fields = fields
          end

          def to_h
            map_for(self.class.serializer_class, fields)
          end

          def map_for(serializer, fields, stack = [])
            serializer.attributes.each_with_object({}) do |name_attr, result|
              name = name_attr[0]
              attribute = name_attr[1]
              next unless expose?(attribute, fields)

              raise Error, recursive_error_message(stack, name) if stack.any?(name_attr)
              stack << name_attr

              result[name] =
                if attribute.relation?
                  nested_serializer = attribute.serializer
                  nested_fields = fields&.[](name)
                  map_for(nested_serializer, nested_fields, stack)
                else
                  FROZEN_EMPTY_HASH
                end

              stack.pop
            end
          end

          private

          def expose?(attribute, fields)
            return true if exposed == :all
            return manually_exposed?(attribute, fields) if exposed == :none

            attribute.exposed? || manually_exposed?(attribute, fields)
          end

          def manually_exposed?(attribute, fields)
            fields&.include?(attribute.serialized_name)
          end

          def recursive_error_message(stack, name)
            recursion = (stack.map!(&:first) << name).join(" -> ")
            "Recursive serialization: #{recursion}"
          end
        end

        extend Jat::Helpers::SerializerClassHelper
        extend ClassMethods
        include InstanceMethods
      end
    end
  end
end
