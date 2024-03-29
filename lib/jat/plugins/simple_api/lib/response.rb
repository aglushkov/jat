# frozen_string_literal: true

class Jat
  module Plugins
    module SimpleApi
      class Response
        module ClassMethods
          def call(object, context)
            new(object, context).to_h
          end
        end

        module InstanceMethods
          attr_reader :object, :context, :serializer_class

          def initialize(object, context)
            @object = object
            @context = context
            @serializer_class = self.class.serializer_class
          end

          def to_h
            # Add main response
            is_many = many?
            root = root_key(is_many)

            response = is_many ? many(object) : one(object)
            response = {root => response} if root
            response ||= {}

            add_metadata(response, root)

            response
          end

          private

          def many(objects)
            objects.map { |obj| one(obj) }
          end

          def one(obj)
            map = serializer_class.map(context)
            serializer_class::ResponsePiece.to_h(obj, context, map)
          end

          def many?
            many = context[:many]
            many.nil? ? object.is_a?(Enumerable) : many
          end

          # We can provide nil or false to remove root
          def root_key(is_many)
            if context.key?(:root)
              root = context[:root]
              root ? root.to_sym : root
            else
              config = serializer_class.config
              is_many ? config[:root_many] : config[:root_one]
            end
          end

          # Add metadata to response
          # We can add metadata whether to empty response or to top-level namespace
          # We should not mix metadata with object attributes
          def add_metadata(response, root)
            meta = metadata
            return if meta.empty?

            raise Error, "Response must have a root key to add metadata" if !response.empty? && !root
            response[meta_key] = meta
          end

          def meta_key
            context[:meta_key]&.to_sym || serializer_class.config[:meta_key]
          end

          def metadata
            data = context_metadata

            meta = serializer_class.added_meta
            return data if meta.empty?

            meta.each do |name, attribute|
              next if data.key?(name)

              value = attribute.value(object, context)

              unless value.nil?
                data = data.dup if data.equal?(FROZEN_EMPTY_HASH)
                data[name] = value
              end
            end

            data
          end

          def context_metadata
            context[:meta]&.transform_keys(&:to_sym) || FROZEN_EMPTY_HASH
          end
        end

        extend Jat::Helpers::SerializerClassHelper
        extend ClassMethods
        include InstanceMethods
      end
    end
  end
end
