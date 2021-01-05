# frozen_string_literal: true

class Jat
  class AttributeParams
    module Checks
      class OptsPreload < Checks::Base
        def validate
          preloads = opts[:preload]
          return unless preloads

          check_object(preloads)
        end

        private

        def check_object(preloads)
          case preloads
          when Symbol, String then check_empty_string(preloads)
          when Hash then check_hash(preloads)
          when Array then check_array(preloads)
          else
            error 'Attribute option `preload` can include only hashes, arrays, strings and symbols'
          end
        end

        def check_hash(preloads)
          preloads.each do |key, val|
            check_hash_key(key)
            check_object(val)
          end
        end

        def check_array(preloads)
          preloads.each { |val| check_object(val) }
        end

        def check_hash_key(key)
          if string?(key)
            check_empty_string(key)
          else
            error "Attribute option `preload` can include only strings or symbols, but #{key.inspect} was provided"
          end
        end

        def check_empty_string(value)
          return unless value.empty?

          error 'Attribute option `preload` can not include empty strings'
        end

        def string?(value)
          value.is_a?(String) || value.is_a?(Symbol)
        end
      end
    end
  end
end
