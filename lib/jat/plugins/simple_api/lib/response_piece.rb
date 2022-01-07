# frozen_string_literal: true

# Serializes to JSON-API format
class Jat
  module Plugins
    module SimpleApi
      class ResponsePiece
        module ClassMethods
          # Returns the Jat class that this ResponsePiece class is namespaced under.
          attr_accessor :jat_class

          # Since ResponsePiece is anonymously subclassed when Jat is subclassed,
          # and then assigned to a constant of the Jat subclass, make inspect
          # reflect the likely name for the class.
          def inspect
            "#{jat_class.inspect}::ResponsePiece"
          end

          def to_h(object, context, map)
            new(object, context).piece(map)
          end
        end

        module InstanceMethods
          attr_reader :jat_class, :object, :context

          def initialize(object, context)
            @object = object
            @context = context
            @jat_class = self.class.jat_class
          end

          def piece(map)
            return unless object

            result = {}

            map.each do |key, inner_map|
              attribute = jat_class.attributes.fetch(key)
              value = attribute.value(object, context)

              result[key] =
                if attribute.relation?
                  if many?(attribute, value)
                    value.map { |obj| inner_piece(attribute, obj, inner_map) }
                  else
                    inner_piece(attribute, value, inner_map)
                  end
                else
                  value
                end
            end

            result
          end

          private

          def inner_piece(attribute, value, inner_map)
            serializer = attribute.serializer.call
            serializer::ResponsePiece.to_h(value, context, inner_map)
          end

          def many?(attribute, nested_object)
            is_many = attribute.many?

            # handle boolean
            return is_many if (is_many == true) || (is_many == false)

            # handle nil
            nested_object.is_a?(Enumerable)
          end
        end

        extend ClassMethods
        include InstanceMethods
      end
    end
  end
end
