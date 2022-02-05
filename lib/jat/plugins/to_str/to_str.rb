# frozen_string_literal: true

class Jat
  module Plugins
    module ToStr
      def self.plugin_name
        :to_str
      end

      def self.load(serializer_class, **_opts)
        serializer_class.include(InstanceMethods)
        serializer_class.extend(ClassMethods)
      end

      def self.after_load(serializer_class, **opts)
        serializer_class.config[:to_str] = opts[:to_str] || ->(data) { ToStrJSON.dump(data) }
      end

      module ClassMethods
        def to_str(object, context = nil)
          new(context || FROZEN_EMPTY_HASH).to_str(object)
        end
      end

      module InstanceMethods
        def to_str(object)
          hash = to_h(object)
          self.class.config[:to_str].call(hash)
        end
      end

      class ToStrJSON
        module ClassMethods
          def dump(response)
            json_adapter.dump(response)
          end

          private

          def json_adapter
            @json_adapter ||= begin
              require "json"
              ::JSON
            end
          end
        end

        extend ClassMethods
      end
    end

    register_plugin(ToStr.plugin_name, ToStr)
  end
end
