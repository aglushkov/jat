# frozen_string_literal: true

class Jat
  class Opts
    class Serializer
      class << self
        def call(value)
          value.is_a?(Proc) ? proc_serializer(value) : value
        end

        private

        # :reek:FeatureEnvy
        def proc_serializer(value)
          lambda do
            serializer = value.()

            if !serializer.is_a?(Class) || !(serializer < Jat)
              raise Jat::Error, "Invalid serializer `#{serializer.inspect}`, must be a subclass of Jat"
            end

            serializer
          end
        end
      end
    end
  end
end
