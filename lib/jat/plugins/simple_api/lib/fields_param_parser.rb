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
            attribute = +""
            path_stack = nil

            fields.each_char do |char|
              case char
              when COMMA
                add_attribute(res, path_stack, attribute, FROZEN_EMPTY_HASH)
              when CLOSE_BRACKET
                add_attribute(res, path_stack, attribute, FROZEN_EMPTY_HASH)
                path_stack&.pop
              when OPEN_BRACKET
                name = add_attribute(res, path_stack, attribute, {})
                (path_stack ||= []).push(name) if name
              else
                attribute.insert(-1, char)
              end
            end

            add_attribute(res, path_stack, attribute, FROZEN_EMPTY_HASH)

            res
          end

          private

          def add_attribute(res, path_stack, attribute, nested_attributes = FROZEN_EMPTY_HASH)
            attribute.strip!
            return if attribute.empty?

            name = attribute.to_sym
            attribute.clear

            current_attrs = !path_stack || path_stack.empty? ? res : res.dig(*path_stack)
            current_attrs[name] = nested_attributes

            name
          end
        end

        extend ClassMethods
        include InstanceMethods
      end
    end
  end
end
