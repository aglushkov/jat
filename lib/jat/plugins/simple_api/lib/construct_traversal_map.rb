# frozen_string_literal: true

# Combines all serializer and its relations exposed fields into one hash.
class Jat
  module Plugins
    module SimpleApi
      class ConstructTraversalMap
        attr_reader :jat_class, :exposed, :manually_exposed

        def initialize(jat_class, exposed, manually_exposed: nil)
          @jat_class = jat_class
          @exposed = exposed.to_sym
          @manually_exposed = manually_exposed || {}
        end

        def to_h
          jat_class.attributes.each_with_object({}) do |(name, attribute), result|
            next unless expose?(attribute)

            result[name] =
              if attribute.relation?
                self.class.new(attribute.serializer.call, exposed, manually_exposed: manually_exposed[name]).to_h
              else
                {}
              end
          end
        end

        private

        def expose?(attribute)
          case exposed
          when :all then true
          when :none then manually_exposed?(attribute)
          else attribute.exposed? || manually_exposed?(attribute)
          end
        end

        def manually_exposed?(attribute)
          manually_exposed.include?(attribute.name)
        end
      end
    end
  end
end
