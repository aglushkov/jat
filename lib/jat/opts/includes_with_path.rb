# frozen_string_literal: true

class Jat
  class Opts
    # We can have includes with a "!" mark that specifies main included resource,
    # which should be used to include nested associations.
    #
    # We should remove this "!" and save path to this marked association.
    class IncludesWithPath
      BANG = '!'

      class << self
        def call(includes)
          path = main_path(includes)

          # Return if path does not end with bang.
          return [includes, path] if path.last[-1] != BANG

          # We should remove bangs from last key in path and from associated includes key.
          # We use mutable methods here.
          remove_bangs(includes, path)
          [includes, path]
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

        def remove_bangs(includes, path)
          # Remove last path with bang
          bang_key = path.pop

          # Delete bang from key
          fine_key = bang_key.to_s.delete_suffix!(BANG).to_sym

          # Navigate to main resource and replace key with BANG
          nested_includes = empty_dig(includes, path)
          nested_includes[fine_key] = nested_includes.delete(bang_key)

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
