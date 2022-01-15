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

            new.parse(fields)
          end
        end

        module InstanceMethods
          COMMA = ","
          OPEN_BRACKET = "("
          CLOSE_BRACKET = ")"

          # user => { user: {} }
          # user(id) => { user: { id: {} } }
          # user(id,name) => { user: { id: {}, name: {} } }
          # user,comments => { user: {}, comments: {} }
          # user(comments(text)) => { user: { comments: { text: {} } } }
          def parse(fields)
            res = {}
            current_attr = +""
            current_route = nil

            fields.each_char do |char|
              if char == COMMA
                add_attribute(res, current_attr, current_route)
                next
              end

              if char == CLOSE_BRACKET
                add_attribute(res, current_attr, current_route)
                current_route&.pop
                next
              end

              if char == OPEN_BRACKET
                current_attr_name = add_attribute(res, current_attr, current_route, {})
                (current_route ||= []) << current_attr_name if current_attr_name
                next
              end

              current_attr.insert(-1, char)
            end

            add_attribute(res, current_attr, current_route)

            res
          end

          private

          def add_attribute(res, current_attr, current_route, nested_attrs = FROZEN_EMPTY_HASH)
            current_attr.strip!
            return if current_attr.empty?

            current_attr_name = current_attr.to_sym
            current_attr.clear

            current_attrs = !current_route || current_route.empty? ? res : res.dig(*current_route)
            current_attrs[current_attr_name] = nested_attrs

            current_attr_name
          end
        end

        extend ClassMethods
        include InstanceMethods
      end
    end
  end
end
