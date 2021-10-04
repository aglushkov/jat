# frozen_string_literal: true

class Jat
  module Plugins
    module ToStr
      def self.apply(jat_class)
        jat_class.include(InstanceMethods)
        jat_class.extend(ClassMethods)
      end

      def self.after_apply(jat_class, **opts)
        jat_class.config[:to_str] = opts[:to_str] || ->(data) { ToStrJSON.dump(data) }
      end

      module ClassMethods
        def to_str(object, context = {})
          new(object, context).to_str
        end
      end

      module InstanceMethods
        def to_str
          config[:to_str].call(to_h)
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

    register_plugin(:to_str, ToStr)
  end
end
