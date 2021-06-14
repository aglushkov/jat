# frozen_string_literal: true

class Jat
  module Plugins
    module SimpleApi
      module Params
        class Parse
          module InstanceMethods
            COMMA = ","
            OPEN_BRACKET = "("
            CLOSE_BRACKET = ")"

            def initialize(fields)
              @fields = fields
              @map = []
              @res = {}
            end

            # user => { user: {} }
            # user(id) => { user: { id: true } }
            # user(id, name) => { user: { id: true, name: true } }
            # user, comments => { user: {}, comments: {} }
            # user(comments(text)) => { user: {}, comments: {} }
            def parse
              return {} unless fields

              current_attr = nil

              fields.each_char do |char|
                case char
                when COMMA
                  add_attribute(current_attr)
                  current_attr = nil
                when CLOSE_BRACKET
                  add_attribute(current_attr)
                  map.pop
                  current_attr = nil
                when OPEN_BRACKET
                  add_attribute(current_attr)
                  map << current_attr.to_sym if current_attr
                  current_attr = nil
                else
                  current_attr = current_attr ? current_attr.insert(-1, char) : char
                end
              end
              add_attribute(current_attr)

              res
            end

            private

            attr_reader :fields, :map, :res

            def add_attribute(current_attr)
              return unless current_attr

              current_resource = map.empty? ? res : res.dig(*map)
              current_resource[current_attr.to_sym] = {}
            end
          end

          include InstanceMethods
        end
      end
    end
  end
end
