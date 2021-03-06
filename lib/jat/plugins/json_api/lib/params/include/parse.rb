# frozen_string_literal: true

class Jat
  module Plugins
    module JsonApi
      module Params
        class Include
          class Parse
            COMMA = ","
            DOT = "."

            class << self
              def call(includes_string)
                return {} unless includes_string

                string_to_hash(includes_string)
              end

              private

              def string_to_hash(includes_string)
                includes_string.split(COMMA).each_with_object({}) do |part, obj|
                  includes = parse_part(part)
                  deep_merge!(obj, includes)
                end
              end

              def parse_part(part)
                val = {}

                part.split(DOT).reverse_each do |inc|
                  val = {inc.to_sym => val}
                end

                val
              end

              def deep_merge!(this_hash, other_hash)
                this_hash.merge!(other_hash) do |_key, this_val, other_val|
                  deep_merge(this_val, other_val)
                end
              end

              def deep_merge(this_hash, other_hash)
                this_hash.merge(other_hash) do |_key, this_val, other_val|
                  deep_merge(this_val, other_val)
                end
              end
            end
          end
        end
      end
    end
  end
end
