# frozen_string_literal: true

class Jat
  class Opts
    module Checks
      class OptsIncludes < Checks::Base
        def validate
          includes = opts[:includes]
          return unless includes

          check_object(includes)
        end

        private

        def check_object(includes)
          case includes
          when Symbol, String then check_empty_string(includes)
          when Hash then check_hash(includes)
          when Array then check_array(includes)
          else
            error 'Attribute option `includes` can include only hashes, arrays, strings and symbols'
          end
        end

        def check_hash(includes)
          includes.each do |key, val|
            check_hash_key(key)
            check_object(val)
          end
        end

        def check_array(includes)
          includes.each { |val| check_object(val) }
        end

        def check_hash_key(key)
          if string?(key)
            check_empty_string(key)
          else
            error "Attribute option `includes` can include only strings or symbols, but #{key.inspect} was provided"
          end
        end

        def check_empty_string(value)
          return unless value.empty?

          error 'Attribute option `includes` can not include empty strings'
        end

        def string?(value)
          value.is_a?(String) || value.is_a?(Symbol)
        end
      end
    end
  end
end
