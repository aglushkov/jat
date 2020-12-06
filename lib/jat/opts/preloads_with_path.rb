# frozen_string_literal: true

class Jat
  class Opts
    # We can have preloads with a "!" mark that specifies main included resource,
    # which will be used to include nested associations.
    #
    # We should remove this "!" and save path to this marked association.
    class PreloadsWithPath
      BANG = '!'

      class << self
        def call(preloads)
          path = main_path(preloads)

          # Return if path does not end with bang.
          return [preloads, path] if path.last[-1] != BANG

          # We should remove bangs from last key in path and from associated preloads key.
          # We use mutable methods here.
          remove_bangs(preloads, path)
          [preloads, path]
        end

        private

        # Generates path (Array) to main included resource (that should be used to preload associations).
        # User should mark main included resource with "!"
        # If nothing is marked, last included resource is considered main.
        #
        #  main_path(a: { b!: { c: {} }, d: {} }) # => [:a, :b!]
        #  main_path(a: { b: { c: {} }, d: {} }) # => [:a, :d]
        #
        # :reek:DuplicateMethodCall (path.size)
        # :reek:TooManyStatements
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
          fine_key = bang_key.to_s.delete_suffix!(BANG).to_sym

          # Navigate to main resource and replace key with BANG
          nested_preloads = empty_dig(preloads, path)
          nested_preloads[fine_key] = nested_preloads.delete(bang_key)

          # Add cleared key to path
          path << fine_key
        end

        def empty_dig(hash, path)
          path.empty? ? hash : hash.dig(*path)
        end
      end
    end
  end
end
