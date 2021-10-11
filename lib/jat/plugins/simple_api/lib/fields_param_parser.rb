# frozen_string_literal: true

class Jat
  module Plugins
    module SimpleApi
      class FieldsParamParser
        module ClassMethods
          # Returns the Jat class that this FieldsParamParser class is namespaced under.
          attr_accessor :jat_class

          # Since FieldsParamParser is anonymously subclassed when Jat is subclassed,
          # and then assigned to a constant of the Jat subclass, make inspect
          # reflect the likely name for the class.
          def inspect
            "#{jat_class.inspect}::FieldsParamParser"
          end

          def parse(fields)
            return FROZEN_EMPTY_HASH unless fields

            new(fields).parse
          end
        end

        module InstanceMethods
          COMMA = ","
          OPEN_BRACKET = "("
          CLOSE_BRACKET = ")"

          def initialize(fields)
            @fields = fields
          end

          # user => { user: {} }
          # user(id) => { user: { id: {} } }
          # user(id,name) => { user: { id: {}, name: {} } }
          # user,comments => { user: {}, comments: {} }
          # user(comments(text)) => { user: { comments: { text: {} } } }
          def parse
            current_attr = nil

            fields.each_char do |char|
              case char
              when COMMA
                next unless current_attr

                add_attribute(current_attr)
                current_attr = nil
              when CLOSE_BRACKET
                if current_attr
                  add_attribute(current_attr)
                  current_attr = nil
                end

                route.pop
              when OPEN_BRACKET
                next unless current_attr

                attribute_name = add_attribute(current_attr, {})
                route << attribute_name
                current_attr = nil
              else
                current_attr = current_attr ? current_attr.insert(-1, char) : char
              end
            end

            add_attribute(current_attr) if current_attr

            res
          end

          private

          attr_reader :fields

          def add_attribute(current_attr, nested_attrs = FROZEN_EMPTY_HASH)
            current_resource = route.empty? ? res : res.dig(*route)
            attribute_name = current_attr.strip.to_sym
            current_resource[attribute_name] = nested_attrs
            attribute_name
          end

          def res
            @res ||= {}
          end

          def route
            @route ||= []
          end
        end

        extend ClassMethods
        include InstanceMethods
      end
    end
  end
end
