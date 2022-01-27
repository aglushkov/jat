# frozen_string_literal: true

class Jat
  module Plugins
    module BasePreloads
      class PreloadsWithPath
        module ClassMethods
          BANG = "!"
          NO_PRELOADS = [{}.freeze, [].freeze].freeze

          # @param preloads [Hash] Formatted user provided preloads hash
          def call(preloads)
            return NO_PRELOADS if preloads.empty?

            path = main_path(preloads)
            return [preloads, path] unless has_bang?(path)

            # We should remove bangs from last key in path and from associated preloads key.
            # We use mutable methods here.
            remove_bangs(preloads, path)
            [preloads, path]
          end

          private

          # Generates path (Array) to main included resource.
          # We need to know main included resource to include nested associations.
          #
          # User should mark main included resource with "!"
          # When nothing marked, last included resource is considered main.
          #
          #  main_path(a: { b!: { c: {} }, d: {} }) # => [:a, :b]
          #  main_path(a: { b: { c: {} }, d: {} }) # => [:a, :d]
          #
          def main_path(hash, path = [])
            current_level = path.size

            hash.each do |key, data|
              path.pop(path.size - current_level)
              path << key
              return path if key[-1] == BANG

              main_path(data, path)
              return path if path.last[-1] == BANG
            end

            path
          end

          def remove_bangs(preloads, path)
            # Remove last path with bang
            bang_key = path.pop

            # Delete bang from key
            key = bang_key.to_s.delete_suffix!(BANG).to_sym

            # Navigate to main resource and replace key with BANG
            nested_preloads = empty_dig(preloads, path)
            nested_preloads[key] = nested_preloads.delete(bang_key)

            # Add cleared key to path
            path << key
          end

          def empty_dig(hash, path)
            path.empty? ? hash : hash.dig(*path)
          end

          def has_bang?(path)
            path.last[-1] == BANG
          end
        end

        extend ClassMethods
      end
    end
  end
end
